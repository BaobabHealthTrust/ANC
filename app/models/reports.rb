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
        }, @start_date, @end_date]).collect{|o| o.patient_id}.uniq.length
  end
  
	def observations_total
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}
  end
  
	def observations_1
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}.delete_if{|x, y| y > 1}
    
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =1")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =1")
		end
=end    
	end

	def observations_2
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}.delete_if{|x, y| y != 2}

=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =2")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =2")
		end
=end    
	end


	def observations_3
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}.delete_if{|x, y| y != 3}

=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =3")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =3")
		end
=end    
	end


	def observations_4
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}.delete_if{|x, y| y != 4}

=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =4")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =4")
		end
=end    
	end


	def observations_5
    
    Encounter.find(:all, :group => ["patient_id"],  
      :select => ["COUNT(DISTINCT encounter_datetime) encounter_id, patient_id"],
      :conditions => ["patient_id IN (?) AND encounter_datetime <= ?", 
        @cohortpatients, @end_date]).collect{|e| 
      [e.patient_id, e.encounter_id]}.delete_if{|x, y| y < 5}

=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount >5")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount >5")
		end
=end    
	end


	def week_of_first_visit_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0-12') OR value_numeric = '0-12' OR value_boolean = '0-12' OR value_datetime = '0-12' OR value_text = '0-12') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0-12') OR value_numeric = '0-12' OR value_boolean = '0-12' OR value_datetime = '0-12' OR value_text = '0-12') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fansida__sp___number_of_tablets_given_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0') OR value_numeric = '0' OR value_boolean = '0' OR value_datetime = '0' OR value_text = '0') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0') OR value_numeric = '0' OR value_boolean = '0' OR value_datetime = '0' OR value_text = '0') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fansida__sp___number_of_tablets_given_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fefo__number_of_tablets_given_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>=0 AND <=119') OR value_numeric = '>=0 AND <=119' OR value_boolean = '>=0 AND <=119' OR value_datetime = '>=0 AND <=119' OR value_text = '>=0 AND <=119') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>=0 AND <=119') OR value_numeric = '>=0 AND <=119' OR value_boolean = '>=0 AND <=119' OR value_datetime = '>=0 AND <=119' OR value_text = '>=0 AND <=119') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fefo__number_of_tablets_given_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'UNKNOWN') OR value_numeric = 'UNKNOWN' OR value_boolean = 'UNKNOWN' OR value_datetime = 'UNKNOWN' OR value_text = 'UNKNOWN') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'UNKNOWN') OR value_numeric = 'UNKNOWN' OR value_boolean = 'UNKNOWN' OR value_datetime = 'UNKNOWN' OR value_text = 'UNKNOWN') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE IN THE LAST 3 MONTHS') OR value_numeric = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_boolean = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_datetime = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_text = 'NEGATIVE IN THE LAST 3 MONTHS') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE IN THE LAST 3 MONTHS') OR value_numeric = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_boolean = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_datetime = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_text = 'NEGATIVE IN THE LAST 3 MONTHS') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE EVER') OR value_numeric = 'POSITIVE EVER' OR value_boolean = 'POSITIVE EVER' OR value_datetime = 'POSITIVE EVER' OR value_text = 'POSITIVE EVER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE EVER') OR value_numeric = 'POSITIVE EVER' OR value_boolean = 'POSITIVE EVER' OR value_datetime = 'POSITIVE EVER' OR value_text = 'POSITIVE EVER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_4
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_5
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NOT DONE') OR value_numeric = 'NOT DONE' OR value_boolean = 'NOT DONE' OR value_datetime = 'NOT DONE' OR value_text = 'NOT DONE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NOT DONE') OR value_numeric = 'NOT DONE' OR value_boolean = 'NOT DONE' OR value_datetime = 'NOT DONE' OR value_text = 'NOT DONE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '!='NO' AND !='YES'') OR value_numeric = '!='NO' AND !='YES'' OR value_boolean = '!='NO' AND !='YES'' OR value_datetime = '!='NO' AND !='YES'' OR value_text = '!='NO' AND !='YES'') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '!='NO' AND !='YES'') OR value_numeric = '!='NO' AND !='YES'' OR value_boolean = '!='NO' AND !='YES'' OR value_datetime = '!='NO' AND !='YES'' OR value_text = '!='NO' AND !='YES'') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
=end
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
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount 'ON ART?' = 'NO' AND 'NUMBER OF SDNVP GIVEN MOTHER' = 0 AND 'NUMBER OF AZT GIVEN TO MOTHER' = 0")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount 'ON ART?' = 'NO' AND 'NUMBER OF SDNVP GIVEN MOTHER' = 0 AND 'NUMBER OF AZT GIVEN TO MOTHER' = 0")
		end
=end
	end


	def pmtct_management_2
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount ON ART?")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount ON ART?")
		end
=end
	end


	def pmtct_management_3
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount NUMBER OF SDNVP GIVEN MOTHER")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount NUMBER OF SDNVP GIVEN MOTHER")
		end
=end
	end


	def pmtct_management_4
=begin    
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount NUMBER OF AZT GIVEN TO MOTHER")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'PMTCT MANAGEMENT') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount NUMBER OF AZT GIVEN TO MOTHER")
		end
=end
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

=begin
	def observations_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =1")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =1")
		end
	end


	def observations_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =2")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =2")
		end
	end


	def observations_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =3")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =3")
		end
	end


	def observations_4
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =4")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount =4")
		end
	end


	def observations_5
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount >5")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient LEFT OUTER JOIN (SELECT patient_id, COUNT(patient_id) AS pcount FROM encounter WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'OBSERVATIONS') AND voided = 0 AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}' GROUP BY patient_id) AS view ON view.patient_id = patient.patient_id WHERE view.patient_id = patient.patient_id AND view.pcount >5")
		end
	end


	def week_of_first_visit_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0-12') OR value_numeric = '0-12' OR value_boolean = '0-12' OR value_datetime = '0-12' OR value_text = '0-12') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'WEEK OF FIRST VISIT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0-12') OR value_numeric = '0-12' OR value_boolean = '0-12' OR value_datetime = '0-12' OR value_text = '0-12') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NO') OR value_numeric = 'NO' OR value_boolean = 'NO' OR value_datetime = 'NO' OR value_text = 'NO') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def pre_eclampsia_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'PRE-ECLAMPSIA') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR value_numeric = 'YES' OR value_boolean = 'YES' OR value_datetime = 'YES' OR value_text = 'YES') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
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
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fansida__sp___number_of_tablets_given_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0') OR value_numeric = '0' OR value_boolean = '0' OR value_datetime = '0' OR value_text = '0') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '0') OR value_numeric = '0' OR value_boolean = '0' OR value_datetime = '0' OR value_text = '0') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fansida__sp___number_of_tablets_given_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FANSIDA (SP): NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>2') OR value_numeric = '>2' OR value_boolean = '>2' OR value_datetime = '>2' OR value_text = '>2') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fefo__number_of_tablets_given_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>=0 AND <=119') OR value_numeric = '>=0 AND <=119' OR value_boolean = '>=0 AND <=119' OR value_datetime = '>=0 AND <=119' OR value_text = '>=0 AND <=119') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>=0 AND <=119') OR value_numeric = '>=0 AND <=119' OR value_boolean = '>=0 AND <=119' OR value_datetime = '>=0 AND <=119' OR value_text = '>=0 AND <=119') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def fefo__number_of_tablets_given_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120' OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def syphilis_result_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'UNKNOWN') OR value_numeric = 'UNKNOWN' OR value_boolean = 'UNKNOWN' OR value_datetime = 'UNKNOWN' OR value_text = 'UNKNOWN') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'SYPHILIS RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'UNKNOWN') OR value_numeric = 'UNKNOWN' OR value_boolean = 'UNKNOWN' OR value_datetime = 'UNKNOWN' OR value_text = 'UNKNOWN') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_1
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE IN THE LAST 3 MONTHS') OR value_numeric = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_boolean = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_datetime = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_text = 'NEGATIVE IN THE LAST 3 MONTHS') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE IN THE LAST 3 MONTHS') OR value_numeric = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_boolean = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_datetime = 'NEGATIVE IN THE LAST 3 MONTHS' OR value_text = 'NEGATIVE IN THE LAST 3 MONTHS') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE EVER') OR value_numeric = 'POSITIVE EVER' OR value_boolean = 'POSITIVE EVER' OR value_datetime = 'POSITIVE EVER' OR value_text = 'POSITIVE EVER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE EVER') OR value_numeric = 'POSITIVE EVER' OR value_boolean = 'POSITIVE EVER' OR value_datetime = 'POSITIVE EVER' OR value_text = 'POSITIVE EVER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NEGATIVE') OR value_numeric = 'NEGATIVE' OR value_boolean = 'NEGATIVE' OR value_datetime = 'NEGATIVE' OR value_text = 'NEGATIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_4
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'POSITIVE') OR value_numeric = 'POSITIVE' OR value_boolean = 'POSITIVE' OR value_datetime = 'POSITIVE' OR value_text = 'POSITIVE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def hiv_test_result_5
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NOT DONE') OR value_numeric = 'NOT DONE' OR value_boolean = 'NOT DONE' OR value_datetime = 'NOT DONE' OR value_text = 'NOT DONE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'HIV TEST RESULT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NOT DONE') OR value_numeric = 'NOT DONE' OR value_boolean = 'NOT DONE' OR value_datetime = 'NOT DONE' OR value_text = 'NOT DONE') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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
		[]
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
		[]
	end


	def pmtct_management_2
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') OR value_numeric = 'ON ART?' OR value_boolean = 'ON ART?' OR value_datetime = 'ON ART?' OR value_text = 'ON ART?') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'ON ART?') OR value_numeric = 'ON ART?' OR value_boolean = 'ON ART?' OR value_datetime = 'ON ART?' OR value_text = 'ON ART?') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def pmtct_management_3
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NUMBER OF SDNVP GIVEN MOTHER') OR value_numeric = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_boolean = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_datetime = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_text = 'NUMBER OF SDNVP GIVEN MOTHER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NUMBER OF SDNVP GIVEN MOTHER') OR value_numeric = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_boolean = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_datetime = 'NUMBER OF SDNVP GIVEN MOTHER' OR value_text = 'NUMBER OF SDNVP GIVEN MOTHER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
	end


	def pmtct_management_4
		case @type
    when 'cohort'
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NUMBER OF AZT GIVEN TO MOTHER') OR value_numeric = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_boolean = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_datetime = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_text = 'NUMBER OF AZT GIVEN TO MOTHER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
    else
      @cases = Patient.find_by_sql("SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'PMTCT MANAGEMENT') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'NUMBER OF AZT GIVEN TO MOTHER') OR value_numeric = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_boolean = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_datetime = 'NUMBER OF AZT GIVEN TO MOTHER' OR value_text = 'NUMBER OF AZT GIVEN TO MOTHER') AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') >= '#{@start_date}' AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') <= '#{@end_date}')")
		end
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

=end
end
