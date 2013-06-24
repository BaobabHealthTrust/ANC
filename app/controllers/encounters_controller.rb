class EncountersController < ApplicationController
  before_filter :find_patient, :except => [:void, :probe_lmp]

  def create
    @patient = Patient.find(params[:encounter][:patient_id])
    # raise params.to_yaml    
    
    if params[:void_encounter_id]
      @encounter = Encounter.find(params[:void_encounter_id])
      @encounter.void
    end
    
    # Go to the dashboard if this is a non-encounter
    redirect_to "/patients/show/#{@patient.id}" unless params[:encounter]

    # Encounter handling
    encounter = Encounter.new(params[:encounter])
    encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
    encounter.save    

    # Observation handling
    (params[:observations] || []).each do |observation|

      # Check to see if any values are part of this observation
      # This keeps us from saving empty observations
      values = ['coded_or_text', 'coded_or_text_multiple', 'group_id', 'boolean', 'coded', 'drug', 'datetime', 'numeric', 'modifier', 'text'].map{|value_name|
        observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
      }.compact

      next if values.length == 0
      
      observation[:value_text] = observation[:value_text].join(", ") if observation[:value_text].present? && observation[:value_text].is_a?(Array)
      observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
      
      observation[:encounter_id] = encounter.id
      # observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
      observation[:person_id] ||= encounter.patient_id
      observation[:concept_name] ||= "DIAGNOSIS" if encounter.type.name == "DIAGNOSIS"
      # Handle multiple select
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array)
        observation[:value_coded_or_text_multiple].compact!
        observation[:value_coded_or_text_multiple].reject!{|value| value.blank?}
      end  
      if observation[:value_coded_or_text_multiple] && observation[:value_coded_or_text_multiple].is_a?(Array) && !observation[:value_coded_or_text_multiple].blank?
        values = observation.delete(:value_coded_or_text_multiple)
        values.each{|value| observation[:value_coded_or_text] = value; Observation.create(observation) }
      else           
        observation.delete(:value_coded_or_text_multiple)
        Observation.create(observation)        
      end
    end

    # Program handling
    date_enrolled = params[:programs][0]['date_enrolled'].to_time rescue nil
    date_enrolled = session[:datetime] || Time.now() if date_enrolled.blank?
    (params[:programs] || []).each do |program|
      # Look up the program if the program id is set      
      @patient_program = PatientProgram.find(program[:patient_program_id]) unless program[:patient_program_id].blank?
    
      # If it wasn't set, we need to create it
      unless (@patient_program)
        @patient_program = @patient.patient_programs.create(
          :program_id => program[:program_id],
          :date_enrolled => date_enrolled)          
      end
      
      # raise program[:states].to_yaml
      # Lots of states bub
      unless program[:states].blank?
        #adding program_state start date
        program[:states][0]['start_date'] = date_enrolled
      end
      (program[:states] || []).each {|state| @patient_program.transition(state) }
    end

    # Identifier handling
    arv_number_identifier_type = PatientIdentifierType.find_by_name('ARV Number').id
    (params[:identifiers] || []).each do |identifier|
      # Look up the identifier if the patient_identfier_id is set      
      @patient_identifier = PatientIdentifier.find(identifier[:patient_identifier_id]) unless identifier[:patient_identifier_id].blank?
      # Create or update
      type = identifier[:identifier_type].to_i rescue nil
      unless (arv_number_identifier_type != type) and @patient_identifier
        arv_number = identifier[:identifier].strip
        if arv_number.match(/(.*)[A-Z]/i).blank?
          identifier[:identifier] = "#{Location.current_arv_code} #{arv_number}"
        end
      end

      if @patient_identifier
        @patient_identifier.update_attributes(identifier)      
      else
        @patient_identifier = @patient.patient_identifiers.create(identifier)
      end
    end
    
    if((CoreService.get_global_property_value("create.from.dde.server") == true) && !@patient.nil?)
      dde_patient = DDEService::Patient.new(@patient)
      identifier = dde_patient.get_full_identifier("National id").identifier rescue nil
      national_id_replaced = dde_patient.check_old_national_id(identifier)
      if national_id_replaced
        print_and_redirect("/patients/national_id_label?patient_id=#{@patient.id}&old_patient=true", next_task(dde_patient.patient)) and return
      end
    end

    redirect_to "/patients/print_registration?patient_id=#{@patient.id}" and return if ((encounter.type.name.upcase rescue "") == 
        "REGISTRATION")
      
    redirect_to "/patients/print_history/?patient_id=#{@patient.id}" and return if (encounter.type.name.upcase rescue "") == 
      "SOCIAL HISTORY"

    @anc_patient = (ANCService::ANC.new(@patient) rescue nil) if @anc_patient.nil?
    
    @current_range = @anc_patient.active_range((session[:datetime] ? session[:datetime].to_date : Date.today)) # rescue nil

    @preg_encounters = @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]) rescue []
    
    @names = @preg_encounters.collect{|e|
      e.name.upcase
    }.uniq
    
    if next_task(@patient) == "/patients/current_pregnancy/?patient_id=#{@patient.id}" && @names.include?("CURRENT PREGNANCY")
      redirect_to "/patients/hiv_status/?patient_id=#{@patient.id}" and return
    end
    
    # Go to the next task in the workflow (or dashboard)
    redirect_to next_task(@patient) 
  end

  def new
    # raise @anc_patient.to_yaml
    @current_range = @anc_patient.active_range((session[:datetime] ? session[:datetime].to_date : Date.today)) rescue nil
    
    @weeks = @anc_patient.fundus rescue 12
       
    @pregnancystart = (session[:datetime]? (session[:datetime].to_date rescue Date.today) : Date.today) - (@weeks.week rescue 0)
    
    @preg_encounters = @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]) rescue []
    
    @names = @preg_encounters.collect{|e|
      e.name.upcase
    }.uniq
    
    if next_task(@patient) == "/patients/current_pregnancy/?patient_id=#{@patient.id}" && @names.include?("CURRENT PREGNANCY")
      redirect_to "/patients/hiv_status/?patient_id=#{@patient.id}" and return
    end
    
    redirect_to next_task(@patient) and return unless params[:encounter_type]
    
    redirect_to :action => :create, 'encounter[encounter_type_name]' => params[:encounter_type].upcase, 'encounter[patient_id]' => @patient.id and return if ['registration'].include?(params[:encounter_type])

    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def diagnoses

    search_string         = (params[:search_string] || '').upcase

    diagnosis_concepts    = Concept.find_by_name("MATERNITY DIAGNOSIS LIST").concept_members_names.sort.uniq # rescue []

    @results = diagnosis_concepts.collect{|e| e}.delete_if{|x| !x.match(/^#{search_string}/)}

    render :text => "<li>" + @results.join("</li><li>") + "</li>"
    
  end

  def treatment
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []
    valid_answers = []
    unless search_string.blank?
      drugs = Drug.find(:all, :conditions => ["name LIKE ?", '%' + search_string + '%'])
      valid_answers = drugs.map {|drug| drug.name.upcase }
    end
    treatment = ConceptName.find_by_name("TREATMENT").concept
    previous_answers = Observation.find_most_common(treatment, search_string)
    suggested_answers = (previous_answers + valid_answers).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
    render :text => "<li>" + suggested_answers.join("</li><li>") + "</li>"
  end
  
  def locations
    search_string = (params[:search_string] || 'neno').upcase
    filter_list = params[:filter_list].split(/, */) rescue []    
    locations =  Location.find(:all, :select =>'name', :conditions => ["name LIKE ?", '%' + search_string + '%'])
    render :text => "<li>" + locations.map{|location| location.name }.join("</li><li>") + "</li>"
  end

  def observations
    # We could eventually include more here, maybe using a scope with includes
    @encounter = Encounter.find(params[:id], :include => [:observations])
    render :layout => false
  end

  def void 
    @encounter = Encounter.find(params[:id])
    @encounter.void
    head :ok
  end

  # List ARV Regimens as options for a select HTML element
  # <tt>options</tt> is a hash which should have the following keys and values
  #
  # <tt>patient</tt>: a Patient whose regimens will be listed
  # <tt>use_short_names</tt>: true, false (whether to use concept short names or
  #  names)
  #
  def arv_regimen_answers(options = {})
    answer_array = Array.new
    regimen_types = ['FIRST LINE ANTIRETROVIRAL REGIMEN', 
      'ALTERNATIVE FIRST LINE ANTIRETROVIRAL REGIMEN',
      'SECOND LINE ANTIRETROVIRAL REGIMEN'
    ]

    regimen_types.collect{|regimen_type|
      Concept.find_by_name(regimen_type).concept_members.flatten.collect{|member|
        next if member.concept.fullname.include?("Triomune Baby") and !options[:patient].child?
        next if member.concept.fullname.include?("Triomune Junior") and !options[:patient].child?
        if options[:use_short_names]
          include_fixed = member.concept.fullname.match("(fixed)")
          answer_array << [member.concept.shortname, member.concept_id] unless include_fixed
          answer_array << ["#{member.concept.shortname} (fixed)", member.concept_id] if include_fixed
          member.concept.shortname
        else
          answer_array << [member.concept.fullname.titleize, member.concept_id] unless member.concept.fullname.include?("+")
          answer_array << [member.concept.fullname, member.concept_id] if member.concept.fullname.include?("+")
        end
      }
    }
    
    if options[:show_other_regimen]
      answer_array << "Other" if !answer_array.blank?
    end
    answer_array

    # raise answer_array.inspect
  end
  
  def static_locations
    search_string = (params[:search_string] || "").upcase
    extras = ["Health Facility", "Home", "TBA", "Other"]
    
    locations = []

    File.open(RAILS_ROOT + "/public/data/locations.txt", "r").each{ |loc|
      locations << loc if loc.upcase.strip.match(search_string)
    }

    if params[:extras]
      extras.each{|loc| locations << loc if loc.upcase.strip.match(search_string)}
    end
    
    render :text => "<li></li><li " + locations.map{|location| "value=\"#{location}\">#{location}" }.join("</li><li ") + "</li>"

  end
  
  def anc_diagnoses

    search_string         = (params[:search_string] || '').upcase
    exceptions = []
    
    params.each{|key, param|
      exceptions << param if key.match(/^v\d/)
    }
    
    diagnosis_concepts = ["Malaria", 
      "Anaemia", 
      "Severe Anaemia", 
      "Pre-eclampsia", 
      "Eclampsia", 
      "Vaginal Bleeding", 
      "Severe Headache", 
      "Blurred vision", 
      "Oedema", 
      "Dizziness", 
      "Fever", 
      "Early rupture of membranes", 
      "Premature Labour", 
      "Labour Pains", 
      "Abdominal Pain", 
      "Pneumonia", 
      "Threatened Abortion", 
      "Extensive Warts"] - exceptions
  
    @results = diagnosis_concepts.collect{|e| e}.delete_if{|x| !x.match(/^#{search_string}/)}

    render :text => "<li>" + @results.join("</li><li>") + "</li>"
    
  end

  def probe_lmp
    #a quick probe of LMP for Maternity obstetric history
    national_id = params[:national_id]
    patient_id = PatientIdentifier.find_by_identifier(national_id).patient_id rescue nil
    concept_id = ConceptName.find_by_name("Last Menstrual Period").concept_id rescue nil
    result = Hash.new
    lmp =  Observation.find(:last, :order => ["obs_datetime"], :conditions => ["person_id = ? AND concept_id = ? AND voided = 0 AND obs_datetime > ?",
        patient_id, concept_id, 9.months.ago]).answer_string.to_date rescue nil if patient_id.present? and concept_id.present?

    result["lmp"] = lmp if lmp
    render :text => result.to_json
  end

  def procedure_done
    @procedure_done = [""] + Concept.find_by_name("PROCEDURE DONE").concept_answers.collect{|c| c.name}.sort

    unless params[:nonone]
      @procedure_done = @procedure_done.insert(0, @procedure_done.delete_at(@procedure_done.index("None")))
    end

    render :text => "<li>" + @procedure_done.join("</li><li>") + "</li>"
  end
  
end
