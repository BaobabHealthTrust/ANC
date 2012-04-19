class EncounterTypesController < ApplicationController

  def index
    @available_encounter_types = User.current_user.activities.reject{|activity| 
      CoreService.get_global_property_value("disable_tasks").split(",").include?(activity)
    } rescue current_user.activities   
  end

  def show
    # raise params.to_yaml
    art_url = GlobalProperty.find_by_property("art_link").property_value.gsub(/http\:\/\//, "") rescue nil
    
    paths = {
      "Weight and Height" => [1, "/encounters/new/vitals/?patient_id=#{patient.id}&weight=1&height=1", "VITALS", 5089, nil, "TODAY"],
      "TTV Vaccination" => [2, "/prescriptions/ttv/?patient_id=#{patient.id}", "TREATMENT", 7124, nil, "TODAY"],  
      "BP" => [3, "/encounters/new/vitals/?patient_id=#{patient.id}&bp=1", "VITALS", 5085, nil, "TODAY"], 
      "ANC Visit Type" => [4, "/patients/visit_type/?patient_id=#{patient.id}", "ANC VISIT TYPE", nil, nil, "TODAY"],  
      "Obstetric History" => [5, "/patients/obstetric_history/?patient_id=#{patient.id}", "OBSTETRIC HISTORY", nil, nil, "EXISTS"],  
      "Medical History" => [6, "/patients/medical_history/?patient_id=#{patient.id}", "MEDICAL HISTORY", nil, nil, "EXISTS"],  
      "Surgical History" => [7, "/patients/surgical_history/?patient_id=#{patient.id}", "SURGICAL HISTORY", nil, nil, "EXISTS"],  
      "Social History" => [8, "/patients/social_history/?patient_id=#{patient.id}", "SOCIAL HISTORY", nil, nil, "EXISTS"], 
      "Lab Results" => [9, "/encounters/new/lab_results/?patient_id=#{patient.id}", "LAB RESULTS", nil, nil, "TODAY"], 
      "ANC Examination" => [10, "/patients/observations/?patient_id=#{patient.id}", "OBSERVATIONS", nil, nil, "TODAY"], 
      "Current Pregnancy" => [11, "/patients/current_pregnancy/?patient_id=#{patient.id}", "CURRENT PREGNANCY", nil, nil, "RECENT"], 
      "Manage Appointments" => [12, "/encounters/new/appointment/?patient_id=#{patient.id}", "APPOINTMENT", nil, nil, "TODAY"], 
      "Give Drugs" => [13, "/prescriptions/give_drugs/?patient_id=#{patient.id}", "TREATMENT", nil, 7124, "TODAY"], 
      "Update Outcome" => [14, "/patients/outcome/?patient_id=#{patient.id}", "UPDATE OUTCOME", nil, nil, "TODAY"], 
      "ART Initial" => [15, "http://#{art_url}/encounters/new/art_initial?action=show&controller=" + 
        "encounter_types&encounter_type=ART+initial&id=show&patient_id=#{patient.id}", "ART INITIAL", nil, nil, "EXISTS"], 
      "HIV Staging" => [16, "http://#{art_url}/encounters/new/hiv_staging?action=show&" + 
        "controller=encounter_types&encounter_type=HIV+staging&id=show&patient_id=#{patient.id}", "HIV STAGING", nil, nil, "EXISTS"],  
      "HIV Reception" => [17, "http://#{art_url}/encounters/new/hiv_reception?action=show" + 
        "&controller=encounter_types&encounter_type=HIV+reception&id=show&patient_id=#{patient.id}", "HIV RECEPTION", nil, nil, "TODAY"], 
      "ART Visit" => [18, "http://#{art_url}/encounters/new/art_visit?action=show&controller=" + 
        "encounter_types&encounter_type=ART+visit&id=show&patient_id=#{patient.id}", "ART VISIT", nil, nil, "TODAY"], 
      "ART Adherence" => [19, "http://#{art_url}/encounters/new/art_adherence?action=show&controller" + 
        "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}", "ART ADHERENCE", nil, nil, "TODAY"],  
      "Manage ART Prescriptions" => [20, "http://#{art_url}/encounters/new/art_adherence?action=show&controller" + 
        "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}", "TREATMENT", nil, nil, "TODAY"],
      "ART Drug Dispensations" => [21, "http://#{art_url}/dispensations/new?patient_id=#{patient.id}", "DISPENSING", nil, nil, "TODAY"]
    }
    
    redirect_to "#{paths[params["encounter_type"].downcase][1]}" and return
  end

end
