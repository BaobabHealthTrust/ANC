# app/controllers/reports_controller.rb

class ReportsController < ApplicationController

  def index
		@start_date = nil
		@end_date = nil
		@start_age = params[:startAge]
		@end_age = params[:endAge]
		@type = params[:selType]

		case params[:selSelect]
		when "day"
      @start_date = params[:day]
      @end_date = params[:day]
		when "week"
      @start_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) -
        ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
      @end_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) +
        6 - ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
		when "month"
			@start_date = ("#{params[:selYear]}-#{params[:selMonth]}-01").to_date.strftime("%Y-%m-%d")
			@end_date = ("#{params[:selYear]}-#{params[:selMonth]}-#{ (params[:selMonth].to_i != 12 ?
        ("#{params[:selYear]}-#{params[:selMonth].to_i + 1}-01".to_date - 1).strftime("%d") : "31") }").to_date.strftime("%Y-%m-%d")
		when "year"
			@start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
			@end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")
		when "quarter"

			day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)
			@start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
			@end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))
		when "range"
			@start_date = params[:start_date]
			@end_date = params[:end_date]
		end
 
		report = Reports.new(@start_date, @end_date, @start_age, @end_age, @type)

		@observations_1 = report.observations_1

		@observations_2 = report.observations_2

		@observations_3 = report.observations_3

		@observations_4 = report.observations_4

		@observations_5 = report.observations_5

		@week_of_first_visit_1 = report.week_of_first_visit_1

		@week_of_first_visit_2 = report.week_of_first_visit_2

		@pre_eclampsia_1 = report.pre_eclampsia_1

		@pre_eclampsia_2 = report.pre_eclampsia_2

		@ttv__total_previous_doses_1 = report.ttv__total_previous_doses_1

		@ttv__total_previous_doses_2 = report.ttv__total_previous_doses_2

		@fansida__sp___number_of_tablets_given_1 = report.fansida__sp___number_of_tablets_given_1

		@fansida__sp___number_of_tablets_given_2 = report.fansida__sp___number_of_tablets_given_2

		@fefo__number_of_tablets_given_1 = report.fefo__number_of_tablets_given_1

		@fefo__number_of_tablets_given_2 = report.fefo__number_of_tablets_given_2

		@syphilis_result_1 = report.syphilis_result_1

		@syphilis_result_2 = report.syphilis_result_2

		@syphilis_result_3 = report.syphilis_result_3

		@hiv_test_result_1 = report.hiv_test_result_1

		@hiv_test_result_2 = report.hiv_test_result_2

		@hiv_test_result_3 = report.hiv_test_result_3

		@hiv_test_result_4 = report.hiv_test_result_4

		@hiv_test_result_5 = report.hiv_test_result_5

		@on_art__1 = report.on_art__1 

		@on_art__2 = report.on_art__2

		@on_art__3 = report.on_art__3

		@on_cpt__1 = report.on_cpt__1

		@on_cpt__2 = report.on_cpt__2

		@pmtct_management_1 = report.pmtct_management_1

		@pmtct_management_2 = report.pmtct_management_2

		@pmtct_management_3 = report.pmtct_management_3

		@pmtct_management_4 = report.pmtct_management_4

		@nvp_baby__1 = report.nvp_baby__1

		@nvp_baby__2 = report.nvp_baby__2

    render :layout => false
  end
  
	def report
    @facility = Location.current_health_center.name rescue ''
    
		@start_date = nil
    @end_date = nil
		@start_age = params[:startAge]
		@end_age = params[:endAge]
		@type = params[:selType]

		case params[:selSelect]
		when "day"
      @start_date = params[:day]
      @end_date = params[:day]
		when "week"
      @start_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) -
        ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
      @end_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) +
        6 - ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
		when "month"
			@start_date = ("#{params[:selYear]}-#{params[:selMonth]}-01").to_date.strftime("%Y-%m-%d")
			@end_date = ("#{params[:selYear]}-#{params[:selMonth]}-#{ (params[:selMonth].to_i != 12 ?
        ("#{params[:selYear]}-#{params[:selMonth].to_i + 1}-01".to_date - 1).strftime("%d") : "31") }").to_date.strftime("%Y-%m-%d")
		when "year"
			@start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
			@end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")
		when "quarter"
			day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)
			@start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
			@end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))
		when "range"
			@start_date = params[:start_date]
			@end_date = params[:end_date]
		end

    	@start_date = params[:start_date] if !params[:start_date].blank?
   	 	@end_date = params[:end_date] if !params[:end_date].blank?

		report = Reports.new(@start_date, @end_date, @start_age, @end_age, @type)

    	@new_women_registered = report.new_women_registered
    
    # raise @new_women_registered.to_yaml
    
   		 @observations_total = report.observations_total
    
		@observations_1 = report.observations_1

		@observations_2 = report.observations_2

		@observations_3 = report.observations_3

		@observations_4 = report.observations_4

		@observations_5 = report.observations_5

		@week_of_first_visit_1 = report.week_of_first_visit_1
    
    # raise @week_of_first_visit_1.to_yaml

		@week_of_first_visit_2 = report.week_of_first_visit_2

		@pre_eclampsia_1 = report.pre_eclampsia_1

		@pre_eclampsia_2 = report.pre_eclampsia_2

		@ttv__total_previous_doses_1 = report.ttv__total_previous_doses_1

		@ttv__total_previous_doses_2 = report.ttv__total_previous_doses_2

    	@fansida__sp___number_of_tablets_given_0 = report.fansida__sp___number_of_tablets_given_0
    
		@fansida__sp___number_of_tablets_given_1 = report.fansida__sp___number_of_tablets_given_1

		@fansida__sp___number_of_tablets_given_2 = report.fansida__sp___number_of_tablets_given_2

		@fefo__number_of_tablets_given_1 = report.fefo__number_of_tablets_given_1

		@albendazole = report.albendazole

		@bed_net = report.bed_net

		@syphilis_result_pos = report.syphilis_result_pos

		@syphilis_result_neg = report.syphilis_result_neg

		@syphilis_result_unk = report.syphilis_result_unk

		@hiv_test_result_prev_neg = report.hiv_test_result_prev_neg

    # raise @hiv_test_result_prev_neg.to_yaml
    
		@hiv_test_result_prev_pos = report.hiv_test_result_prev_pos

		@hiv_test_result_neg = report.hiv_test_result_neg

		@hiv_test_result_pos = report.hiv_test_result_pos

		@hiv_test_result_unk = report.hiv_test_result_unk

    	@total_hiv_positive = @hiv_test_result_prev_pos + @hiv_test_result_pos
    
		@not_on_art = report.not_on_art

		@on_art_before = report.on_art_before

		@on_art_zero_to_27 = report.on_art_zero_to_27 
    
    	@on_art_28_plus = report.on_art_28_plus

		@on_cpt__1 = report.on_cpt__1

		@on_cpt__2 = report.on_cpt__2

		@pmtct_management_1 = report.pmtct_management_1

		@pmtct_management_2 = report.pmtct_management_2

		@pmtct_management_3 = report.pmtct_management_3

		@pmtct_management_4 = report.pmtct_management_4

		@nvp_baby__1 = report.nvp_baby__1

		@nvp_baby__2 = report.nvp_baby__2

    render :layout => false
	end

	def select
    render :layout => "application"
	end

  def decompose  
    # raise params.to_yaml
    @facility = Location.current_health_center.name rescue ''
    
    @patients = []
    
    if params[:patients]
      new_women = params[:patients].split(",")
      @patients = Patient.find(:all, :conditions => ["patient_id IN (?)", new_women])
    end
    
    # raise @patients.length.to_yaml
    
    render :layout => false
  end
  
end
