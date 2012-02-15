# app/models/report.rb

class Reports

	# Initialize class
  def initialize(start_date, end_date, start_age, end_age, type)
    # @start_date = start_date.to_date - 1
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"
    @start_age = start_age
    @end_age = end_age
    @type = type
    
    @enddate = @end_date 
    @startdate = (@enddate.to_date - 9.month).strftime("%Y-%m-%d")
    
    @cohortpatients = Encounter.find(:all, :joins => [:observations], :group => [:patient_id], 
      :select => ["MAX(obs_datetime) encounter_datetime, patient_id"], 
      :conditions => ["encounter_type = ? AND concept_id = ? AND (value_datetime >= ? AND value_datetime <= ?)", 
        EncounterType.find_by_name("CURRENT PREGNANCY").id, 
        ConceptName.find_by_name("DATE OF LAST MENSTRUAL PERIOD").concept_id, 
        @startdate, @enddate]).collect{|e| e.patient_id}

  end

  def new_women_registered
    Encounter.find(:all, :select => [:patient_id], 
      :conditions => ["patient_id IN (?) AND encounter_datetime IN (?) AND 
              (encounter_datetime >= ? AND encounter_datetime <= ?)", 
        @cohortpatients, Encounter.find(:all, :group => [:patient_id], 
          :select => ["MIN(encounter_datetime) encounter_datetime"]).collect{|e| 
          e.encounter_datetime
        }, @start_date, @end_date]).collect{|o| o.patient_id}.uniq
  end
  
	def observations_total
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}
    
  end
  
	def observations_1
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 1}.collect{|x, y| x}.uniq
    
	end

	def observations_2
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 2}.collect{|x, y| x}.uniq
    
	end


	def observations_3
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 3}.collect{|x, y| x}.uniq
    
	end


	def observations_4
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 4}.collect{|x, y| x}.uniq
    
	end


	def observations_5
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations], 
      :select => ["patient_id, MAX(value_numeric) form_id"], 
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime <= ?", 
        ConceptName.find_by_name("Reason for visit").concept_id, 
        @cohortpatients, @end_date]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y < 5}.collect{|x, y| x}.uniq
    
	end


	def week_of_first_visit_1
    Encounter.find(:all, :joins => [:observations], 
      :conditions => ["concept_id = ? AND value_text = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("WEEK OF FIRST VISIT").concept_id, "0-12", 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}.uniq
  
	end


	def week_of_first_visit_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '13+') OR value_numeric = '13+' OR value_boolean = '13+' OR value_datetime = '13+' OR value_text = '13+') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '13+') OR value_numeric = '13+' OR value_boolean = '13+' OR value_datetime = '13+' OR value_text = '13+') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def pre_eclampsia_1
    Encounter.find(:all, :joins => [:observations], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("DIAGNOSIS").concept_id, ConceptName.find_by_name("PRE-ECLAMPSIA").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}.uniq
  
	end


	def pre_eclampsia_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def ttv__total_previous_doses_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '=0 OR =1') OR value_numeric = '=0 OR =1' OR value_boolean = '=0 OR =1' OR value_datetime = '=0 OR =1' OR value_text = '=0 OR =1') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '=0 OR =1') OR value_numeric = '=0 OR =1' OR value_boolean = '=0 OR =1' OR value_datetime = '=0 OR =1' OR value_text = '=0 OR =1') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def ttv__total_previous_doses_2
    patients = {}
    
    Encounter.find(:all, :joins => [:observations], 
      :select => ["patient_id, value_numeric form_id"], 
      :conditions => ["concept_id = ? AND value_numeric > 0 AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("TT STATUS").concept_id, 
        @startdate, @enddate, @cohortpatients]).each{|e| 
      patients[e.patient_id] = e.form_id}; 
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id"], 
      :group => [:patient_id], :conditions => ["drug.name LIKE ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "%TTV%", 
        @startdate, @enddate, @cohortpatients]).collect{|o| 
      [o.patient_id, o.encounter_id] }.delete_if{|p, e| 
      v = 0; 
      if patients[p]
        v = patients[p]
      end
      v + e < 2        
    }.collect{|x, y| x}
    
	end


	def fansida__sp___number_of_tablets_given_0
    
    select = Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"], 
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)", 
        @startdate, @enddate, @cohortpatients]).collect{|o| o.patient_id}

    @cohortpatients - select
   
	end
  
	def fansida__sp___number_of_tablets_given_1
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " + 
          "DATEDIFF(auto_expire_date, start_date) orderer"], 
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)", 
        @startdate, @enddate, @cohortpatients]).collect{|o| 
      [o.patient_id, o.orderer]      
    }.delete_if{|x,y| y > 1}.collect{|p, c| p}
    
	end


	def fansida__sp___number_of_tablets_given_2
        
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " + 
          "DATEDIFF(auto_expire_date, start_date) orderer"], 
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)", 
        @startdate, @enddate, @cohortpatients]).collect{|o| 
      [o.patient_id, o.orderer]      
    }.delete_if{|x,y| y < 2}.collect{|p, c| p}
    
	end


	def fefo__number_of_tablets_given_1

		Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +  
          "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id], 
      :conditions => ["drug.name = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "Fefol (1 tablet)", 
        @startdate, @enddate, @cohortpatients]).collect{|o| 
      [o.patient_id, o.orderer]}.delete_if{|x,y| y < 120}.collect{|p, c| p}
    
	end


	def fefo__number_of_tablets_given_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_pos
		# Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"], :conditions => ["concept_id = ? AND value_coded = ?", ConceptName.find_by_name("Syphilis Test Result").concept, ConceptName.find_by_name("Not done").concept_id])

    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("Syphilis Test Result").concept, 
        ConceptName.find_by_name("Positive").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def syphilis_result_neg
		
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("Syphilis Test Result").concept, 
        ConceptName.find_by_name("Positive").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def syphilis_result_unk
		
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("Syphilis Test Result").concept, 
        ConceptName.find_by_name("Not done").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def hiv_test_result_prev_neg
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("HIV status").concept_id, 
        ConceptName.find_by_name("Negative").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.form_id}
   
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :conditions => ["concept_id = ? AND obs_id IN (?) AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?) AND " + 
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')", 
        ConceptName.find_by_name("HIV test date").concept_id, 
        select, @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
  
	end


	def hiv_test_result_prev_pos
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("HIV status").concept_id, 
        ConceptName.find_by_name("Positive").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :conditions => ["concept_id = ? AND obs_id IN (?) AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?) AND " + 
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')", 
        ConceptName.find_by_name("HIV test date").concept_id, 
        select, @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def hiv_test_result_neg
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("HIV status").concept_id, 
        ConceptName.find_by_name("Negative").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :conditions => ["concept_id = ? AND obs_id IN (?) AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?) AND " + 
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')", 
        ConceptName.find_by_name("HIV test date").concept_id, 
        select, @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def hiv_test_result_pos
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("HIV status").concept_id, 
        ConceptName.find_by_name("Positive").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :conditions => ["concept_id = ? AND obs_id IN (?) AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?) AND " + 
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')", 
        ConceptName.find_by_name("HIV test date").concept_id, 
        select, @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def hiv_test_result_unk
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], 
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("HIV status").concept_id, 
        ConceptName.find_by_name("Not done").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
	end


	def on_art__1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def on_art__2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def on_art__3
	end


	def on_cpt__1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON CPT?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON CPT?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def on_cpt__2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON CPT?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON CPT?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def pmtct_management_1
	end


	def pmtct_management_2
	end


	def pmtct_management_3
	end


	def pmtct_management_4
	end


	def nvp_baby__1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'NVP BABY?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'NVP BABY?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def nvp_baby__2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'NVP BABY?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'NVP BABY?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end

  def albendazole
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter], 
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +  
          "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id], 
      :conditions => ["drug.name LIKE ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "Albendazole%", 
        @startdate, @enddate, @cohortpatients]).collect{|o| 
      [o.patient_id, o.orderer]      
    }.delete_if{|x,y| y != 1}.collect{|p, c| p}
    
  end
  
  def bed_net
    
    Encounter.find(:all, :joins => [:observations], 
      :conditions => ["concept_id = ? AND value_coded = ? AND (encounter_datetime >= ? " + 
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", 
        ConceptName.find_by_name("Mosquito Net").concept, 
        ConceptName.find_by_name("Yes").concept_id, 
        @startdate, @enddate, @cohortpatients]).collect{|e| e.patient_id}
    
  end
  
end
