class EncounterTypesController < ApplicationController

  def index
    @available_encounter_types = User.current_user.activities.reject{|activity| 
      CoreService.get_global_property_value("disable_tasks").split(",").include?(activity)
    } rescue current_user.activities   
  end

  def show
    # raise params.to_yaml
    art_url = GlobalProperty.find_by_property("art_link").property_value.gsub(/http\:\/\//, "") rescue nil
    
    patient = Patient.find(params[:patient_id]) rescue nil
    
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
      "Update Outcome" => "/patients/outcome/?patient_id=#{patient.id}", 
      "ART Initial" => "http://#{art_url}/encounters/new/art_initial?action=show&controller=" + 
        "encounter_types&encounter_type=ART+initial&id=show&patient_id=#{patient.id}", 
      "HIV Staging" => "http://#{art_url}/encounters/new/hiv_staging?action=show&" + 
        "controller=encounter_types&encounter_type=HIV+staging&id=show&patient_id=#{patient.id}",  
      "HIV Reception" => "http://#{art_url}/encounters/new/hiv_reception?action=show" + 
        "&controller=encounter_types&encounter_type=HIV+reception&id=show&patient_id=#{patient.id}", 
      "ART Visit" => "http://#{art_url}/encounters/new/art_visit?action=show&controller=" + 
        "encounter_types&encounter_type=ART+visit&id=show&patient_id=#{patient.id}", 
      "ART Adherence" => "http://#{art_url}/encounters/new/art_adherence?action=show&controller" + 
        "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}",  
      "Manage ART Prescriptions" => "http://#{art_url}/encounters/new/art_adherence?action=show&controller" + 
        "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{patient.id}",
      "ART Drug Dispensations" => "http://#{art_url}/dispensations/new?patient_id=#{patient.id}"
    } rescue {}
    
    redirect_to "#{paths[params[:encounter_type]]}" and return
  end

end
