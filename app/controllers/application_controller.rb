class ApplicationController < GenericApplicationController

  def next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = main_next_task(Location.current_location, patient,session_date)

    #We need to know if user terminated previous pregnancy by means of abortion or otherwise just terminated ....
    #
    #1. should have checked abortion status atleast a month ago
    session_date = (session[:datetime].to_date rescue Date.today)
    @current_range = @anc_patient.active_range(session_date)
  
    if request.referrer.match(/people\/search\?|\/clinic/i)
      @current_pregnancy_url =  "/patients/current_pregnancy/?patient_id=#{patient.id}"
      return "/patients/confirm/?patient_id=#{patient.id}&url=#{@current_pregnancy_url}"
    end
    
    begin
      return task.url if task.present? && task.url.present?
      return "/patients/show/#{patient.id}" 
    rescue
      return "/patients/show/#{patient.id}" 
    end
    
  end

  def next_form(location , patient , session_date = Date.today)
    #for ANC Clinic
    task = Task.first rescue Task.new()    

    current_user_activities = current_user.activities.collect{|u| u.downcase}
    
    normal_flow = CoreService.get_global_property_value("list.of.clinical.encounters.sequentially").split(",")

    flow = {}

    (0..(normal_flow.length-1)).each{|n|
      flow[normal_flow[n].downcase] = n+1
    }

    if current_user_activities.blank?
      task.encounter_type = "NO TASKS SELECTED"
      task.url = "/patients/show/#{patient.id}"
      return task
    end
    
    @patient = Patient.find(patient.id) rescue nil
    @anc_patient = ANCService::ANC.new(@patient) rescue nil        
    
    session.delete :datetime if session[:datetime].nil? || 
      ((session[:datetime].to_date.strftime("%Y-%m-%d") rescue Date.today.strftime("%Y-%m-%d")) == Date.today.strftime("%Y-%m-%d"))
        
    # tasks[task] = [weight, path, encounter_type, concept_id, exception_concept_id, 
    #     scope, drug_concept_id, special_field_or_encounter_present, next_if_NOT_condition_met]    
    tasks = {
      "Weight and Height" => [flow["Weight and Height".downcase], "/encounters/new/vitals/?patient_id=#{patient.id}&weight=1&height=1",
        "VITALS", 5089, nil, "TODAY", nil, true, (current_user_activities.include?("Weight and Height".downcase))],
      
      "TTV Vaccination" => [flow["TTV Vaccination".downcase], "/prescriptions/ttv/?patient_id=#{patient.id}",
        "DISPENSING", nil, nil, "TODAY", 7124, false, (current_user_activities.include?("TTV Vaccination".downcase))],
      
      "BP" => [flow["BP".downcase], "/encounters/new/vitals/?patient_id=#{patient.id}&bp=1", "VITALS",
        5085, nil, "TODAY", nil, true, (current_user_activities.include?("BP".downcase))],
      
      "ANC Visit Type" => [flow["ANC Visit Type".downcase], "/patients/visit_type/?patient_id=#{patient.id}",
        "ANC VISIT TYPE", nil, nil, "TODAY", nil, true, (current_user_activities.include?("ANC Visit Type".downcase))],
      
      "Obstetric History" => [flow["Obstetric History".downcase], "/patients/obstetric_history/?patient_id=#{patient.id}",
        "OBSTETRIC HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Obstetric History".downcase))],
      
      "Medical History" => [flow["Medical History".downcase], "/patients/medical_history/?patient_id=#{patient.id}",
        "MEDICAL HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Medical History".downcase))],
      
      "Surgical History" => [flow["Surgical History".downcase], "/patients/surgical_history/?patient_id=#{patient.id}",
        "SURGICAL HISTORY", nil, nil, "EXISTS", nil, false, (current_user_activities.include?("Surgical History".downcase))],
      
      "Social History" => [flow["Social History".downcase], "/patients/social_history/?patient_id=#{patient.id}",
        "SOCIAL HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Social History".downcase))],
      
      "Lab Results" => [flow["Lab Results".downcase], "/encounters/new/lab_results/?patient_id=#{patient.id}",
        "LAB RESULTS", nil, nil, "TODAY", nil, false, (current_user_activities.include?("Lab Results".downcase))],

      "Current Pregnancy" => [flow["Current Pregnancy".downcase], "/patients/current_pregnancy/?patient_id=#{patient.id}",
        "CURRENT PREGNANCY", nil, nil, "RECENT", nil, true, (current_user_activities.include?("Current Pregnancy".downcase))],
      
      "ANC Examination" => [flow["ANC Examination".downcase], "/patients/observations/?patient_id=#{patient.id}",
        "OBSERVATIONS", nil, nil, "TODAY", nil, true, (current_user_activities.include?("ANC Examination".downcase))],
      
      "Manage Appointments" => [flow["Manage Appointments".downcase], "/encounters/new/appointment/?patient_id=#{patient.id}",
        "APPOINTMENT", nil, nil, "TODAY", nil, true, (current_user_activities.include?("Manage Appointments".downcase))],
      
      "Give Drugs" => [flow["Give Drugs".downcase], "/prescriptions/give_drugs/?patient_id=#{patient.id}",
        "TREATMENT", nil, nil, "TODAY", 7124, false, (current_user_activities.include?("Give Drugs".downcase))] # ,
      
      # "Update Outcome" => [17, "/patients/outcome/?patient_id=#{patient.id}", "UPDATE OUTCOME",
      #  nil, nil, "TODAY", nil, true, (current_user_activities.include?("Update Outcome".downcase))]
    }

    session["patient_id_map"] = {} if session["patient_id_map"].nil?
    session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"] = {} if session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"].nil?

    same_database = (CoreService.get_global_property_value("same_database") == "true" ? true : false) rescue false

    # Get patient id mapping
    if @anc_patient.hiv_status.downcase == "positive" && 
        session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil?

      session["proceed_to_art"] = {} if session["proceed_to_art"].nil?
      session["proceed_to_art"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"] = {} if session["proceed_to_art"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"].nil?

      @external_id = Bart2Connection::PatientIdentifier.search_by_identifier(@anc_patient.national_id).person_id rescue nil

      @external_user_id = Bart2Connection::User.find_by_username(current_user.username).id rescue nil

      if !@external_id.nil? && !@external_id.blank?
        session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id] = @external_id rescue nil
        session["user_internal_external_id_map"] = @external_user_id rescue nil        
      end

    end

    if @anc_patient.hiv_status.downcase == "positive" and
        !session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil? and
        !session["user_internal_external_id_map"].nil?

      # art_link = GlobalProperty.find_by_property("art_link").property_value.gsub(/http\:\/\//, "") rescue nil
      # anc_link = GlobalProperty.find_by_property("anc_link").property_value rescue nil

      art_link = CoreService.get_global_property_value("art_link") rescue nil
      anc_link = CoreService.get_global_property_value("anc_link") rescue nil

      # Check ART if valid
      if !art_link.nil? && !anc_link.nil? # && foreign_links.include?(pos)
        if !session[:token]
          response = RestClient.post("http://#{art_link}/single_sign_on/get_token",
            {"login"=>session[:username], "password"=>session[:password]}) rescue nil

          if !response.nil?
            response = JSON.parse(response)

            session[:token] = response["auth_token"]
          end

        end
        # end
       
        @external_encounters = Bart2Connection::PatientIdentifier.search_by_identifier(@anc_patient.national_id).patient.encounters.find(:all,
          :conditions => ["encounter_datetime = ?", (session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")]).collect{|e| e.type.name}

        # raise @external_encounters.to_yaml
      
      
        session["patient_vitals_map"] = {} if session["patient_vitals_map"].nil?
        session["patient_vitals_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"] = {} if session["patient_vitals_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"].nil?

        # Send vitals to ART
        if @anc_patient.current_weight.to_i > 0 and @anc_patient.current_height.to_i > 0 and same_database == false and
            session["patient_vitals_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil?
        
          bmi = ((@anc_patient.current_weight.to_f/(@anc_patient.current_height.to_f *
                @anc_patient.current_height.to_f)) * 10000).round(1) rescue 0

          vitals_params = {
            "obs"=>{
              "obs_set_0"=>{
                "value_numeric"=>"#{@anc_patient.current_weight}",
                "value_coded_or_text_multiple"=>[""],
                "value_drug"=>"",
                "value_modifier"=>"",
                "value_coded"=>"",
                "value_boolean"=>"",
                "obs_group_id"=>"",
                "order_id"=>"",
                "value_text"=>"",
                "patient_id"=>"#{session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id]}",
                "obs_datetime"=>"#{(session[:datetime] ? session[:datetime].to_time : (session[:datetime] ? session[:datetime].to_time :
                DateTime.now()).strftime("%Y-%m-%d %H:%M"))}",
                "concept_name"=>"WEIGHT (KG)",
                "value_coded_or_text"=>"",
                "value_datetime"=>""
              },
              "obs_set_1"=>{
                "value_numeric"=>"#{@anc_patient.current_height}",
                "value_coded_or_text_multiple"=>[""],
                "value_drug"=>"",
                "value_modifier"=>"",
                "value_coded"=>"",
                "value_boolean"=>"",
                "obs_group_id"=>"",
                "order_id"=>"",
                "value_text"=>"",
                "patient_id"=>"#{session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id]}",
                "obs_datetime"=>"#{(session[:datetime] ? session[:datetime].to_time : (session[:datetime] ? session[:datetime].to_time :
                DateTime.now()).strftime("%Y-%m-%d %H:%M"))}",
                "concept_name"=>"HEIGHT (CM)",
                "value_coded_or_text"=>"",
                "value_datetime"=>""
              },
              "obs_set_2"=>{
                "value_numeric"=>"",
                "value_coded_or_text_multiple"=>[""],
                "value_drug"=>"",
                "value_modifier"=>"",
                "value_coded"=>"",
                "value_boolean"=>"",
                "obs_group_id"=>"",
                "order_id"=>"",
                "value_text"=>"",
                "patient_id"=>"#{session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id]}",
                "obs_datetime"=>"#{(session[:datetime] ? session[:datetime].to_time : (session[:datetime] ? session[:datetime].to_time :
                DateTime.now()).strftime("%Y-%m-%d %H:%M"))}",
                "concept_name"=>"BODY MASS INDEX, MEASURED",
                "value_coded_or_text"=>"#{bmi}",
                "value_datetime"=>""
              }
            },
            "encounter"=>{
              "encounter_datetime"=>"#{(session[:datetime] ? session[:datetime].to_time : (session[:datetime] ? session[:datetime].to_time :
              DateTime.now()).strftime("%Y-%m-%d %H:%M"))}",
              "provider_id"=>"#{session["user_internal_external_id_map"]}",
              "patient_id"=>"#{session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id]}",
              "encounter_type_name"=>"VITALS"
            },
            "location"=>(Location.current_location.id rescue Location.first.location_id)
          }

          # Create a VITALS encounter and associated obs in ART
      
          result = RestClient.post("http://#{art_link}/encounters/create_remote", vitals_params) rescue nil

          session["patient_vitals_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id] = true
        end
      
        additional_tasks = {}

        if (!session["proceed_to_art"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"].nil? and
              session["proceed_to_art"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil? and
              !@external_encounters.collect{|u| u.downcase}.include?("hiv reception"))

          additional_tasks["HIV Reception"] = [flow["HIV Reception".downcase], "/patients/go_to_art?patient_id=#{@patient.id}",
            "HIV RECEPTION", nil, nil, "TODAY", nil, false, (current_user_activities.collect{|u| u.downcase}.include?("hiv reception") &&
                @anc_patient.hiv_status.downcase == "positive")]
        
        end
      
        if !(session["user_internal_external_id_map"] rescue nil).nil?
          tasks = tasks.merge(additional_tasks) if @anc_patient.hiv_status.downcase == "positive" && !(session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id] rescue nil).nil?
        end
      end
      # End check ART
      
    end
    
    sorted_tasks = {}
    
    tasks.each{|t,v|
      sorted_tasks[v[0]] = t
    }
    
    sorted_tasks = sorted_tasks.sort

    sorted_tasks.each do |pos, tsk|
      
      # next if tasks[tsk][8] == false
      if tasks[tsk][8] == false
        task.encounter_type = tsk
        task.url = "/patients/show/#{patient.id}"
        return task
      end
      
      case tasks[tsk][5]
      when "TODAY"
        
        checked_already = false
        
        if !tasks[tsk][3].nil? && checked_already == false    # Check for presence of specific concept_id
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][3], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        if !tasks[tsk][4].nil? && checked_already == false   # Check for concept exclusions from encounter_type group
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND NOT obs.concept_id = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][4], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ? AND start_date = ?",
              tasks[tsk][6], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        # Else check for availability of encounter_type
        if checked_already == false
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), session_date.to_date]) rescue []
        
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        task.encounter_type = tsk
        
        if normal_flow[0].downcase == tsk.downcase
          task.url = tasks[tsk][1]
        else
          task.url = "/patients/show/#{patient.id}"
        end
        return task
      when "RECENT"
        
        checked_already = false
        
        if !tasks[tsk][3].nil? && checked_already == false    # Check for presence of specific concept_id
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ? " +
                "AND (DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?)",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][3],
              (session_date.to_date - 6.month), (session_date.to_date + 6.month)]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        if !tasks[tsk][4].nil? && checked_already == false   # Check for concept exclusions from encounter_type group
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND NOT obs.concept_id = ? " +
                "AND (DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?)",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][4],
              (session_date.to_date - 6.month), (session_date.to_date + 6.month)]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ? AND start_date = ? " +
                "AND (DATE(start_date) >= ? AND DATE(start_date) <= ?)",
              tasks[tsk][6], (session_date.to_date - 6.month), (session_date.to_date + 6.month)]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        # Else check for availability of encounter_type
        if checked_already == false
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? " +
                "AND (DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?)",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]),
              (session_date.to_date - 6.month), (session_date.to_date + 6.month)]) rescue []
        
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        task.encounter_type = tsk
        
        if normal_flow[0].downcase == tsk.downcase
          task.url = tasks[tsk][1]
        else
          task.url = "/patients/show/#{patient.id}"
        end
        return task
      when "EXISTS"
        
        checked_already = false
          
        if !tasks[tsk][3].nil? && checked_already == false    # Check for presence of specific concept_id
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][3]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        if !tasks[tsk][4].nil? && checked_already == false   # Check for concept exclusions from encounter_type group
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ? AND NOT obs.concept_id = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][4]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ?",
              tasks[tsk][6]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        # Else check for availability of encounter_type
        if checked_already == false
          available = Encounter.find(:all, :joins => [:observations], :conditions =>
              ["patient_id = ? AND encounter_type = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2])]) rescue []
        
          if available.length > 0
            if normal_flow[0].downcase == tsk.downcase
              normal_flow -= [tsk.downcase]
              next
            end
          end
        end
        
        task.encounter_type = tsk
        
        if normal_flow[0].downcase == tsk.downcase
          task.url = tasks[tsk][1]
        else
          task.url = "/patients/show/#{patient.id}"
        end
        return task
      end
      
    end
    
    #task.encounter_type = 'Visit complete ...'
    task.encounter_type = 'NONE'
    task.url = "/patients/show/#{patient.id}"
    return task
  end

  # Try to find the next task for the patient at the given location
  def main_next_task(location, patient, session_date = Date.today)

    if use_user_selected_activities
      return next_form(location , patient , session_date)
    end
    all_tasks = Task.all(:order => 'sort_weight ASC')
    todays_encounters = patient.encounters.find_by_date(session_date)
    todays_encounter_types = todays_encounters.map{|e| e.type.name rescue ''}.uniq rescue []
    
    active_encounters = patient.encounters
    
    all_tasks.each do |task|
      # next if todays_encounters.map{ | e | e.name }.include?(task.encounter_type)
      # Is the task for this location?
      next unless task.location.blank? || task.location == '*' || location.name.match(/#{task.location}/)

      # Have we already run this task?
      # next if task.encounter_type.present? && todays_encounter_types.include?(task.encounter_type)

      # By default, we don't want to skip this task
      skip = false
 
      # Skip this task if this is a gender specific task and the gender does not match?
      # For example, if this is a female specific check and the patient is not female, we want to skip it
      skip = true if task.gender.present? && patient.person.gender != task.gender

      # Check for an observation made today with a specific value, skip this task unless that observation exists
      # For example, if this task is the art_clinician task we want to skip it unless REFER TO CLINICIAN = yes
      if task.has_obs_concept_id.present?
        if (task.has_obs_scope.blank? || task.has_obs_scope == 'TODAY')

          obs = Observation.first(:conditions => [
              "encounter_id IN (?) AND concept_id = '?'",
              todays_encounters.map(&:encounter_id),
              task.has_obs_concept_id])
          
        end
        
        # Only the most recent obs
        # For example, if there are mutliple REFER TO CLINICIAN = yes, than only take the most recent one
        if (task.has_obs_scope == 'RECENT')
          o = patient.person.observations.recent(1).first(:conditions =>
              ['encounter_id IN (?) AND concept_id =? AND DATE(obs_datetime)=?',
              todays_encounters.map(&:encounter_id), task.has_obs_concept_id,session_date])
          
          obs = 0 if (o.value_coded == task.has_obs_value_coded && o.value_drug == task.has_obs_value_drug &&
              o.value_datetime == task.has_obs_value_datetime && o.value_numeric == task.has_obs_value_numeric &&
              o.value_text == task.has_obs_value_text )
        end
          
        skip = true if obs.present?
      else
        next if todays_encounters.map{ | e | e.name }.include?(task.encounter_type)
      end

      if task.has_obs_value_drug && task.has_obs_scope == 'TODAY'
        obs = patient.orders.first(:conditions => ["concept_id = ? AND start_date = ?",
            task.has_obs_value_drug, session_date])
        
        skip = true if obs.present?
      end
      
      # Only if this encounter type exists
      if (task.has_obs_scope == 'EXISTS')
        obs = patient.person.observations.first(:conditions => ['encounter_id IN (?)',
            active_encounters.all(:conditions => ["encounter_type = ?",
                EncounterType.find_by_name(task.encounter_type).id]).map(&:encounter_id)])
        
        skip = true if obs.present?
      end
        
      # Check for a particular current order type, skip this task unless the order exists
      # For example, if this task is /dispensation/new we want to skip it if there is not already a drug order
      if task.has_order_type_id.present?
        skip = true unless Order.unfinished.first(:conditions => {:order_type_id => task.has_order_type_id}).present?
      end

      if task.has_encounter_type_today.present?
        enc = nil
        if todays_encounters.collect{|e|e.name}.include?(task.has_encounter_type_today)
          enc = task.has_encounter_type_today
        end
        skip = true if !enc.nil?
      end

      # Reverse the condition if the task wants the negative (for example, if the patient doesn't have a specific program yet, then run this task)
      skip = !skip if task.skip_if_has == 1

      # We need to skip this task for some reason
      next if skip

      # Nothing failed, this is the next task, lets replace any macros
      task.url = task.url.gsub(/\{patient\}/, "#{patient.patient_id}")
      task.url = task.url.gsub(/\{person\}/, "#{patient.person.person_id rescue nil}")
      task.url = task.url.gsub(/\{location\}/, "#{location.location_id rescue nil}")

      logger.debug "next_task: #{task.id} - #{task.description}"
      
      return task
    end
  end

  private

  def find_patient
    @patient = Patient.find(params[:patient_id] || session[:patient_id] || params[:id]) rescue nil
    @anc_patient = ANCService::ANC.new(@patient) rescue nil
  end
  
end
