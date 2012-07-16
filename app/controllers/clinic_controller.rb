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
    @reports = [['/reports/select/','Reports']]
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
    simple_overview_property = CoreService.get_global_property_value("simple_application_dashboard") rescue nil

    simple_overview = false
    if simple_overview_property != nil
      if simple_overview_property == 'true'
        simple_overview = true
      end
    end

    @types = CoreService.get_global_property_value("statistics.show_encounter_types") rescue EncounterType.all.map(&:name).join(",")
    @types = @types.split(/,/)

    @me = Encounter.statistics(@types,
      :conditions => ['encounter_datetime BETWEEN ? AND ? AND encounter.creator = ?',
                      Date.today.strftime('%Y-%m-%d 00:00:00'),
                      Date.today.strftime('%Y-%m-%d 23:59:59'),
                      current_user.user_id])
    @today = Encounter.statistics(@types,
      :conditions => ['encounter_datetime BETWEEN ? AND ?',
                      Date.today.strftime('%Y-%m-%d 00:00:00'),
                      Date.today.strftime('%Y-%m-%d 23:59:59')])

    if !simple_overview
      @year = Encounter.statistics(@types,
        :conditions => ['encounter_datetime BETWEEN ? AND ?',
                        Date.today.strftime('%Y-01-01 00:00:00'),
                        Date.today.strftime('%Y-12-31 23:59:59')])
      @ever = Encounter.statistics(@types)
    end

    @user = User.find(session[:user_id]).person.name rescue ""

    if simple_overview
        render :template => 'clinic/overview_simple.rhtml' , :layout => false
        return
    end
    render :layout => false
  end

  def user_activities
    render :layout => false
  end
  
  def no_males
    render :layout => "menu"
  end
  
end
