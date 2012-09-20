class EncounterTypesController < ApplicationController

  def index 
    @patient = Patient.find(params[:patient_id]) rescue nil
    
    @anc_patient = ANCService::ANC.new(@patient)
    
    @available_encounter_types = User.current_user.activities.reject{|activity| 
      CoreService.get_global_property_value("disable_tasks").split(",").include?(activity)
    } rescue current_user.activities 
    
    hiv_specs = [
      "HIV Reception"
    ]
    
    status = @anc_patient.hiv_status.downcase rescue "unknown"
    
    @available_encounter_types = @available_encounter_types - ["Registration", "View Reports"]
    
    @available_encounter_types = @available_encounter_types - hiv_specs if status != "positive"
    
  end

  def show
    art_link = CoreService.get_global_property_value("art_link") rescue nil
    anc_link = CoreService.get_global_property_value("anc_link") rescue nil

    patient = Patient.find(params[:patient_id]) rescue nil

    @patient = Patient.find(patient.id) rescue nil
    @anc_patient = ANCService::ANC.new(@patient) rescue nil
    
    if !session[:token]
      response = RestClient.post("http://#{art_link}/single_sign_on/get_token", 
        {"login"=>session[:username], "password"=>session[:password]}) rescue nil
          
      if !response.nil?
        response = JSON.parse(response)
            
        session[:token] = response["auth_token"]          
      end
             
    end
    
    session.delete :datetime if session[:datetime].nil? || 
      ((session[:datetime].to_date.strftime("%Y-%m-%d") rescue Date.today.strftime("%Y-%m-%d")) == Date.today.strftime("%Y-%m-%d"))
        
    paths = {
      "Weight and Height" => "/encounters/new/vitals/?patient_id=#{patient.id}&weight=1&height=1",
      
      "TTV Vaccination" => "/prescriptions/ttv/?patient_id=#{patient.id}", 
      
      "BP" => "/encounters/new/vitals/?patient_id=#{patient.id}&bp=1", 
      
      "ANC Visit Type" => "/patients/visit_type/?patient_id=#{patient.id}", 
      
      "Obstetric History" => "/patients/obstetric_history/?patient_id=#{patient.id}",  
      
      "Medical History" => "/patients/medical_history/?patient_id=#{patient.id}",  
      
      "Surgical History" => "/patients/surgical_history/?patient_id=#{patient.id}",  
      
      "Social History" => "/patients/social_history/?patient_id=#{patient.id}", 
      
      "Lab Results" => "/encounters/new/lab_results/?patient_id=#{patient.id}",
      
      "ANC Examination" => "/patients/observations/?patient_id=#{patient.id}", 
      
      "Current Pregnancy" => "/patients/current_pregnancy/?patient_id=#{patient.id}", 
      
      "Manage Appointments" => "/encounters/new/appointment/?patient_id=#{patient.id}", 
      
      "Give Drugs" => "/prescriptions/give_drugs/?patient_id=#{patient.id}", 
      
      "Update Outcome" => "/patients/outcome/?patient_id=#{patient.id}"
    } rescue {}

    session["patient_id_map"] = {["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"] => {}} if session["patient_id_map"].nil?

    # Get patient id mapping
    if @anc_patient.hiv_status.downcase == "positive" && session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil?

      @external_id = Bart2Connection::PatientIdentifier.search_by_identifier(@anc_patient.national_id).person_id rescue nil

      if !@external_id.nil? && !@external_id.blank?
        session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id] = @external_id rescue nil
      end

    end

    if @anc_patient.hiv_status.downcase == "positive" && !session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id].nil?

      art_link = CoreService.get_global_property_value("art_link") rescue nil
      anc_link = CoreService.get_global_property_value("anc_link") rescue nil

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

        @external_encounters = Bart2Connection::PatientIdentifier.search_by_identifier(@anc_patient.national_id).patient.encounters.collect{|e| e.type.name}

      
        paths["HIV Reception"] = "http://#{art_link}/single_sign_on/single_sign_in?auth_token=#{session[:token]}&" +
          "return_uri=http://#{anc_link}/patients/next_url?patient_id=#{@patient.id}&destination_uri=http://#{art_link}" +
          "/encounters/new/hiv_reception/#{session["patient_id_map"]["#{(session[:datetime] || Time.now()).to_date.strftime("%Y-%m-%d")}"][@patient.id]}?from_anc=true&current_location=#{session[:location_id]}"
      end
    end

    redirect_to "#{paths[params[:encounter_type]]}" and return
  end

end
