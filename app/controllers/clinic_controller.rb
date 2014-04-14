class ClinicController < GenericClinicController
  def index
    
    @facility = Location.current_health_center.name rescue ''

    @location = Location.find(session[:location_id]).name rescue ""

    @date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

    @user = User.find(current_user.user_id) rescue nil

    @roles = User.find(current_user.user_id).user_roles.collect{|r| r.role} rescue []

    # raise session.to_yaml

    render :layout => 'dynamic-dashboard'
  end

  def reports
    @reports = [#['/reports/select/','Booking Cohort Report'],
      ['/reports/report_limits', 'Monthly Report'] ,
      ['/reports/select?type=anc_cohort', 'Booking Cohort Report']]

    # render :template => 'clinic/reports', :layout => 'clinic'
    render :layout => false
  end

  def supervision
    @supervision_tools = [["Data that was Updated", "summary_of_records_that_were_updated"],
      ["Drug Adherence Level",    "adherence_histogram_for_all_patients_in_the_quarter"],
      ["Visits by Day",           "visits_by_day"],
      ["Non-eligible Patients in Cohort", "non_eligible_patients_in_cohort"]]

    @landing_dashboard = 'clinic_supervision'

    render :template => 'clinic/supervision', :layout => 'clinic' 
  end

  def properties
    render :template => 'clinic/properties', :layout => 'clinic' 
  end

  def printing
    render :template => 'clinic/printing', :layout => 'clinic' 
  end

  def users
    render :template => 'clinic/users', :layout => 'general'
  end

  def administration
    @reports = [['/clinic/users','User accounts/settings']]
    @landing_dashboard = 'clinic_administration'
    # render :template => 'clinic/administration', :layout => 'clinic'
    render :layout => false
  end

  def overview
    @types = ["1", "2", "3", "4", ">5"]

    @me = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, ">5" => 0}
    @today = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, ">5" => 0}
    @year = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, ">5" => 0}
    @ever = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, ">5" => 0}
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["encounter.creator, encounter_datetime AS date, MAX(value_numeric) form_id"],
      :conditions => ["encounter_type = ? AND concept_id = ? AND (DATE(encounter_datetime) BETWEEN (?) AND (?))",
        EncounterType.find_by_name("ANC VISIT TYPE").id,
        ConceptName.find_by_name("Reason for visit").concept_id,
        Date.today, Date.today]).each do |data|

      cat = data.form_id.to_i
      cat = cat > 4 ? ">5" : cat.to_s
      
      if data.creator.to_i == current_user.user_id.to_i
        @me["#{cat}"] += 1
      end
      @today["#{cat}"] += 1      
    end

    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["encounter.creator, encounter_datetime AS date, MAX(value_numeric) form_id"],
      :conditions => ["encounter_type = ? AND concept_id = ? AND (DATE(encounter_datetime) BETWEEN (?) AND (?))",
        EncounterType.find_by_name("ANC VISIT TYPE").id,
        ConceptName.find_by_name("Reason for visit").concept_id,
        Date.today.beginning_of_year, Date.today.end_of_year]).each do |data|

      cat = data.form_id.to_i
      cat = cat > 4 ? ">5" : cat.to_s
      @year["#{cat}"] += 1
    end
  
    @user = current_user.name rescue ""

    render :layout => false
  end

  def user_activities
    render :layout => false
  end
  
  def no_males
    render :layout => "menu"
  end
  
end
