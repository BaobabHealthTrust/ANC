class ApplicationController < GenericApplicationController

  def next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = main_next_task(Location.current_location, patient,session_date)
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

    current_user_activities = current_user.activities
    
    if current_user_activities.blank?
      task.encounter_type = "NO TASKS SELECTED"
      task.url = "/patients/show/#{patient.id}"
      return task
    end
    
    @patient = Patient.find(patient.id) rescue nil
    @anc_patient = ANCService::ANC.new(@patient) rescue nil        
    
    art_link = GlobalProperty.find_by_property("art_link").property_value.gsub(/http\:\/\//, "") rescue nil
    anc_link = GlobalProperty.find_by_property("anc_link").property_value rescue nil
    
    # tasks[task] = [weight, path, encounter_type, concept_id, exception_concept_id, 
    #     scope, drug_concept_id, special_field_or_encounter_present, next_if_NOT_condition_met]    
    tasks = {
      "Weight and Height" => [1, "/encounters/new/vitals/?patient_id=#{patient.id}&weight=1&height=1", 
        "VITALS", 5089, nil, "TODAY", nil, true, (current_user_activities.include?("Weight and Height"))],
      
      "TTV Vaccination" => [2, "/prescriptions/ttv/?patient_id=#{patient.id}", 
        "DISPENSING", nil, nil, "TODAY", 7124, false, (current_user_activities.include?("TTV Vaccination"))], 
      
      "BP" => [3, "/encounters/new/vitals/?patient_id=#{patient.id}&bp=1", "VITALS", 
        5085, nil, "TODAY", nil, true, (current_user_activities.include?("BP"))],
      
      "ANC Visit Type" => [4, "/patients/visit_type/?patient_id=#{patient.id}", 
        "ANC VISIT TYPE", nil, nil, "TODAY", nil, true, (current_user_activities.include?("ANC Visit Type"))],  
      
      "Obstetric History" => [5, "/patients/obstetric_history/?patient_id=#{patient.id}", 
        "OBSTETRIC HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Obstetric History"))], 
      
      "Medical History" => [6, "/patients/medical_history/?patient_id=#{patient.id}", 
        "MEDICAL HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Medical History"))],  
      
      "Surgical History" => [7, "/patients/surgical_history/?patient_id=#{patient.id}", 
        "SURGICAL HISTORY", nil, nil, "EXISTS", nil, false, (current_user_activities.include?("Surgical History"))],  
      
      "Social History" => [8, "/patients/social_history/?patient_id=#{patient.id}", 
        "SOCIAL HISTORY", nil, nil, "EXISTS", nil, true, (current_user_activities.include?("Social History"))], 
      
      "Lab Results" => [9, "/encounters/new/lab_results/?patient_id=#{patient.id}", 
        "LAB RESULTS", nil, nil, "TODAY", nil, false, (current_user_activities.include?("Lab Results"))], 
      
      "ANC Examination" => [10, "/patients/observations/?patient_id=#{patient.id}", 
        "OBSERVATIONS", nil, nil, "TODAY", nil, true, (current_user_activities.include?("ANC Examination"))], 
      
      "Current Pregnancy" => [11, "/patients/current_pregnancy/?patient_id=#{patient.id}", 
        "CURRENT PREGNANCY", nil, nil, "RECENT", nil, true, (current_user_activities.include?("Current Pregnancy"))], 
      
      "Manage Appointments" => [12, "/encounters/new/appointment/?patient_id=#{patient.id}", 
        "APPOINTMENT", nil, nil, "TODAY", nil, true, (current_user_activities.include?("Manage Appointments"))], 
      
      "Give Drugs" => [13, "/prescriptions/give_drugs/?patient_id=#{patient.id}", 
        "TREATMENT", nil, nil, "TODAY", nil, false, (current_user_activities.include?("Give Drugs"))], 
      
      "Update Outcome" => [14, "/patients/outcome/?patient_id=#{patient.id}", "UPDATE OUTCOME", 
        nil, nil, "TODAY", nil, true, (current_user_activities.include?("Update Outcome"))], 
      
      "HIV Clinic Registration" => [15, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/art_initial?action=show&controller=" + 
          "encounter_types&encounter_type=ART+initial&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "HIV CLINIC REGISTRATION", nil, nil, "EXISTS", nil, false, (current_user_activities.include?("ART Initial") && 
            @anc_patient.hiv_status.downcase == "positive")], 
      
      "HIV Staging" => [16, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/hiv_staging?action=show&" + 
          "controller=encounter_types&encounter_type=HIV+staging&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "HIV STAGING", nil, nil, "EXISTS", nil, false, (current_user_activities.include?("HIV Staging") && 
            @anc_patient.hiv_status.downcase == "positive")],  
      
      "HIV Reception" => [17, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/hiv_reception?action=show" + 
          "&controller=encounter_types&encounter_type=HIV+reception&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "HIV RECEPTION", nil, nil, "TODAY", nil, false, (current_user_activities.include?("HIV Reception") && 
            @anc_patient.hiv_status.downcase == "positive")], 
      
      "HIV Consultation" => [18, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/art_visit?action=show&controller=" + 
          "encounter_types&encounter_type=ART+visit&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "HIV CONSULTATION", nil, nil, "TODAY", nil, false, (current_user_activities.include?("ART Visit") && 
            @anc_patient.hiv_status.downcase == "positive")], 
      
      "ART Adherence" => [19, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/art_adherence?action=show&controller" + 
          "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "ART ADHERENCE", nil, nil, "TODAY", nil, false, (current_user_activities.include?("ART Adherence") && 
            @anc_patient.hiv_status.downcase == "positive")],  
      
      "Manage ART Prescriptions" => [20, "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" + 
          "return_uri=http://#{anc_link}/patients/show/#{@patient.id}&destination_uri=http://#{art_link}" + 
          "/encounters/new/art_adherence?action=show&controller" + 
          "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}&current_location=#{session[:location_id]}", 
        "TREATMENT", nil, nil, "TODAY", nil, false, (current_user_activities.include?("Manage ART Prescriptions") && 
            @anc_patient.hiv_status.downcase == "positive")]
    }
        
    sorted_tasks = {}
    
    tasks.each{|t,v|
      sorted_tasks[v[0]] = t
    }
    
    sorted_tasks = sorted_tasks.sort
    
    foreign_links = [
      "Manage ART Prescriptions",
      "ART Adherence",
      "HIV Clinic Consultation",
      "HIV Reception",
      "HIV Staging",
      "HIV Clinic Registration"
    ]
    
    sorted_tasks.each do |pos, tsk|
      
      if !art_link.nil? && !anc_link.nil? && foreign_links.include?(pos)
        if !session[:token]
          response = RestClient.post("http://#{art_link}/single_sign_on/get_token", 
            {"login"=>session[:username], "password"=>session[:password]}) rescue nil
          
          if !response.nil?
            response = JSON.parse(response)
            
            session[:token] = response["auth_token"]          
          end
               
        end
      end
       
      session.delete :datetime if session[:datetime].nil? || 
      ((session[:datetime].to_date.strftime("%Y-%m-%d") rescue Date.today.strftime("%Y-%m-%d")) == Date.today.strftime("%Y-%m-%d"))
        
      next if tasks[tsk][8] == false
      
      case tasks[tsk][5]
      when "TODAY"
        
        checked_already = false
        
        if !tasks[tsk][3].nil? && checked_already == false    # Check for presence of specific concept_id
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][3], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
        
        if !tasks[tsk][4].nil? && checked_already == false   # Check for concept exclusions from encounter_type group
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ? AND NOT obs.concept_id = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][4], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ? AND start_date = ?", 
              tasks[tsk][6], session_date.to_date]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
        
        # Else check for availability of encounter_type
        if checked_already == false
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), session_date.to_date]) rescue []
        
          if available.length > 0
            next
          end
        end
        
        task.encounter_type = tasks[tsk][2]
        task.url = tasks[tsk][1]
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
            next
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
            next
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ? AND start_date = ? " + 
                "AND (DATE(start_date) >= ? AND DATE(start_date) <= ?)", 
              tasks[tsk][6], (session_date.to_date - 6.month), (session_date.to_date + 6.month)]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
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
            next
          end
        end
        
        task.encounter_type = tasks[tsk][2]
        task.url = tasks[tsk][1]
        return task
      when "EXISTS"
        
        checked_already = false
          
        if !tasks[tsk][3].nil? && checked_already == false    # Check for presence of specific concept_id
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ? AND obs.concept_id = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][3]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
        
        if !tasks[tsk][4].nil? && checked_already == false   # Check for concept exclusions from encounter_type group
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ? AND NOT obs.concept_id = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2]), tasks[tsk][4]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
            
        if !tasks[tsk][6].nil? && checked_already == false   # Check for drug concept if available
          available = patient.orders.all(:conditions => ["concept_id = ?", 
              tasks[tsk][6]]) rescue []
        
          checked_already = tasks[tsk][7]
          if available.length > 0
            next
          end
        end
        
        # Else check for availability of encounter_type
        if checked_already == false
          available = Encounter.find(:all, :joins => [:observations], :conditions => 
              ["patient_id = ? AND encounter_type = ?",
              patient.id, EncounterType.find_by_name(tasks[tsk][2])]) rescue []
        
          if available.length > 0
            next
          end
        end
        
        task.encounter_type = tasks[tsk][2]
        task.url = tasks[tsk][1]
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
    all_tasks = self.all(:order => 'sort_weight ASC')
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
