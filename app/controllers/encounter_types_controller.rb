class EncounterTypesController < ApplicationController

  def index
    @available_encounter_types = User.current_user.activities.reject{|activity| 
      CoreService.get_global_property_value("disable_tasks").split(",").include?(activity)
    } rescue User.current_user.activities   
  end

  def show
    # raise params.to_yaml
    art_url = GlobalProperty.find_by_property("art_link").property_value.gsub(/http\:\/\//, "") rescue nil
    
    paths = {
      'manage prescriptions' => "/prescriptions/give_drugs/?patient_id=#{params[:patient_id]}",
      
      'vitals' => "/encounters/new/vitals?patient_id=#{params[:patient_id]}",
      
      'lab results' => "/encounters/new/lab_results?patient_id=#{params[:patient_id]}",
      
      'update lab results' => "/encounters/new/lab_results?patient_id=#{params[:patient_id]}&update=true",
      
      'anc examinations' => "/patients/observations/?patient_id=#{params[:patient_id]}",
      
      'manage appointments' => "/encounters/new/appointment?patient_id=#{params[:patient_id]}",
      
      'update outcomes' => "/patients/outcome/?patient_id=#{params[:patient_id]}",
      
      'patient history' => "/patients/obstetric_history/?patient_id=#{params[:patient_id]}",
      
      'art initial' => "http://#{art_url}/encounters/new/art_initial?action=show&controller=" + 
        "encounter_types&encounter_type=ART+initial&id=show&patient_id=#{params[:patient_id]}",
      
      'art visit' => "http://#{art_url}/encounters/new/art_visit?action=show&controller=" + 
        "encounter_types&encounter_type=ART+visit&id=show&patient_id=#{params[:patient_id]}",
      
      'hiv reception' => "http://#{art_url}/encounters/new/hiv_reception?action=show" + 
        "&controller=encounter_types&encounter_type=HIV+reception&id=show&patient_id=#{params[:patient_id]}",
      
      'hiv staging' => "http://#{art_url}/encounters/new/hiv_staging?action=show&" + 
        "controller=encounter_types&encounter_type=HIV+staging&id=show&patient_id=#{params[:patient_id]}",
      
      'art adherence' => "http://#{art_url}/encounters/new/art_adherence?action=show&controller" + 
        "=encounter_types&encounter_type=ART+adherence&id=show&patient_id=#{params[:patient_id]}",
      
      'manage art drug dispensations' => "http://#{art_url}/dispensations/new?patient_id=#{params[:patient_id]}",
      
      'manage art prescriptions' => "http://#{art_url}/prescriptions/new?patient_id=#{params[:patient_id]}"
    }
    
    redirect_to "#{paths[params["encounter_type"].downcase]}" and return
  end

end
