# app/models/report.rb

class Reports

	# Initialize class
  def initialize(start_date, end_date, start_age, end_age, type, today=Date.today)
   
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"
    @start_age = start_age
    @end_age = end_age
    @type = type
    @today = today
    @type = "cohort" if @type.blank?
     
    @enddate = @end_date
    @startdate = @start_date
    @preg_range = (@type == "cohort") ? 6.months : ((end_date.to_time - start_date.to_time).round/(3600*24)).days

=begin    
    server = CoreService.get_global_property_value("maternity.links") + "/report/delivered_patients"


    @maternity_data = JSON.parse(RestClient.post(server, {"start_date" => @startdate, "end_date" => @enddate})) rescue {}
    @delivered_patients = @maternity_data["ids"]

    @cohortpatients = PatientIdentifier.find_by_sql(["SELECT pid.patient_id FROM patient_identifier pid WHERE pid.identifier IN (?) AND
     (SELECT (COUNT(*)) FROM encounter enc WHERE enc.patient_id =  pid.patient_id AND encounter_type = ? AND enc.encounter_datetime > ?) > 0",
     @delivered_patients, EncounterType.find_by_name("ANC VISIT TYPE").id, (@start_date.to_date - @preg_range)]).collect{|patient| patient.patient_id}

    Encounter.find(:all, :joins => [:observations], :select => ["patient_id"],
        :conditions => ["patient_id IN (?) AND encounter_type = ? AND concept_id = ? AND (DATE(encounter_datetime) >= ? " +
            "AND DATE(encounter_datetime) <= ?) AND value_numeric = 1 AND encounter.voided = 0",
          @cohortpatients,
          EncounterType.find_by_name("ANC VISIT TYPE").id,
          ConceptName.find_by_name("Reason For Visit").concept_id,
          @startdate, @enddate]).collect{|e| e.patient_id}.uniq
=end
    
    @cohortpatients = registrations(@startdate, @enddate)
    
    @bart_patients = on_art_in_bart
    
    @on_cpt = @bart_patients['on_cpt']
    @on_art_before = @bart_patients['arv_before_visit_one']
 
    @bart_patients.delete("on_cpt")
    @bart_patients.delete("arv_before_visit_one")
    @bart_patient_identifiers = @bart_patients.keys
  end

  def registrations(start_dt, end_dt)

    Encounter.find(:all, :joins => [:observations], :group => [:patient_id],
      :select => ["MAX(value_datetime) lmp, patient_id"],
      :conditions => ["encounter_type = ? AND concept_id = ? AND encounter_datetime >= ? " +
          "AND encounter_datetime <= ? AND encounter.voided = 0",
        EncounterType.find_by_name("Current Pregnancy").id,
        ConceptName.find_by_name("Date of Last Menstrual Period").concept_id,
        start_dt, end_dt]).collect{|e| e.patient_id}.uniq
    
  end

  def new_women_registered

    if @type == "cohort"
           
      registrations(@today.beginning_of_month, @today.end_of_month)
      
    else

      @cohortpatients
      
    end
  end
  
  def observations_total
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)",
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| 
      [e.patient_id, e.form_id]
    }.collect{|x, y| x if y.present?}.uniq
    
  end
  
  def observations_1
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)",
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 1}.collect{|x, y| x}.uniq
    
  end

  def observations_2
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)",
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 2}.collect{|x, y| x}.uniq
    
  end

  def observations_3
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)",
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 3}.collect{|x, y| x}.uniq
    
  end


  def observations_4
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)" ,
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y != 4}.collect{|x, y| x}.uniq
    
  end


  def observations_5
    
    Encounter.find(:all, :group => ["person_id"], :joins => [:observations],
      :select => ["patient_id, MAX(value_numeric) form_id"],
      :conditions => ["concept_id = ? AND patient_id IN (?) AND encounter_datetime BETWEEN (?) AND (?)",
        ConceptName.find_by_name("Reason for visit").concept_id,
        @cohortpatients, @startdate, (@startdate.to_date + @preg_range)]).collect{|e| [e.patient_id, e.form_id]}.delete_if{|x, y| y < 5}.collect{|x, y| x}.uniq
    
  end


  def week_of_first_visit_1
   
    @cases = Encounter.find(:all, :joins => [:observations],
      :conditions => ["concept_id = ? AND value_numeric <= 12 AND encounter_datetime BETWEEN (?) AND (?)" +
          " AND patient_id IN (?)",
        ConceptName.find_by_name("WEEK OF FIRST VISIT").concept_id,
        @start_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}.uniq

    @cases
  end


  def week_of_first_visit_2
   
    @cases = Encounter.find(:all, :joins => [:observations],
      :conditions => ["concept_id = ? AND value_numeric >= 12 AND encounter_datetime BETWEEN (?) AND (?)" +
          " AND patient_id IN (?)",
        ConceptName.find_by_name("WEEK OF FIRST VISIT").concept_id,
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}.uniq
   
    @cases
  end


  def pre_eclampsia_2
    
    Encounter.find(:all, :joins => [:observations],
      :conditions => ["concept_id = ? AND value_coded = ? AND encounter_datetime BETWEEN (?) AND (?)" +
          "AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("DIAGNOSIS").concept_id, ConceptName.find_by_name("PRE-ECLAMPSIA").concept_id,
        @startdate, (@startdate.to_date + @preg_range) , @cohortpatients]).collect{|e| e.patient_id}.uniq
  
  end


  def pre_eclampsia_1
    
    @cases1 = Encounter.find(:all, :joins => [:observations],
      :conditions => ["concept_id = ? AND value_coded IN (?) AND encounter_datetime BETWEEN (?) AND (?)" +
          "AND encounter.patient_id IN (?)",

        ConceptName.find_by_name("DIAGNOSIS").concept_id,
        ["ECLAMPSIA", "PRE-ECLAMPSIA"].collect{|name| ConceptName.find_by_name(name).concept_id},
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}.uniq
    
    @cases2 = Patient.find_by_sql(["SELECT * FROM patient WHERE patient_id IN " +
          "(SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = " +
          "obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name REGEXP 'ECLAMPSIA') " +
          "AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR " +
          "value_text = 'YES') AND " +
          "DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?) AND patient_id IN (?)", @startdate.to_date, (@startdate.to_date - @preg_range).to_date, @cohortpatients]).collect{|cas| cas.patient_id}

    @cases = (@cases1 + @cases2).uniq
        
  end


  def ttv__total_previous_doses_1
    
    @cases = Patient.find_by_sql(["SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '=0 OR =1') OR value_numeric = '=0 OR =1' OR value_boolean = '=0 OR =1' OR value_datetime = '=0 OR =1' OR value_text = '=0 OR =1') AND encounter_datetime >= ? AND encounter_datetime <= ?)", @startdate, (@startdate.to_date + @preg_range)]).collect{|p| p.patient_id}.uniq
   
  end

  def ttv__total_previous_doses_2
    patients = {}
    
    Encounter.find(:all, :joins => [:observations],
      :select => ["patient_id, (COALESCE(value_numeric,0)+COALESCE(value_text,0)) form_id"],
      :conditions => ["concept_id = ? AND (value_numeric > 0 OR value_text > 0) AND encounter_datetime BETWEEN (?) AND (?)" +
          "AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("TT STATUS").concept_id,
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).each{|e|
      patients[e.patient_id] = e.form_id};
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id"],
      :group => [:patient_id], :conditions => ["drug.name LIKE ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?) AND orders.voided = 0", "%TTV%",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o|
      [o.patient_id, o.encounter_id] }.delete_if{|p, e|
      v = 0;
      v = patients[p] if patients[p]
      v.to_i + e.to_i < 2
    }.collect{|x, y| x}.uniq
    
  end


  def fansida__sp___number_of_tablets_given_0
    
    select = Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o| o.patient_id}

    @cohortpatients - select
   
  end
  
  def fansida__sp___number_of_tablets_given_1
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o|
      [o.patient_id, o.encounter_id]
    }.delete_if{|x,y| y != 1}.collect{|p, c| p}
    
  end


  def fansida__sp___number_of_tablets_given_2
        
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
      :group => [:patient_id], :conditions => ["drug.name = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o|
      [o.patient_id, o.encounter_id]
    }.delete_if{|x,y| y != 2}.collect{|p, c| p}
    
  end


  def fefo__number_of_tablets_given_1

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
          "COALESCE(SUM(DATEDIFF(auto_expire_date, start_date)), 0) orderer"], :group => [:patient_id],
      :conditions => ["drug.name = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "Fefol (1 tablet)",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o|
      [o.patient_id, o.orderer]}.delete_if{|x,y| y < 120}.collect{|p, c| p}
    
  end


  def fefo__number_of_tablets_given_2
    
    @cases = Patient.find_by_sql(["SELECT * FROM patient
              WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id
                      WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'FEFO: NUMBER OF TABLETS GIVEN')
                      AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '>120') OR value_numeric = '>120'
                      OR value_boolean = '>120' OR value_datetime = '>120' OR value_text = '>120')
                      AND encounter_datetime >= ? AND encounter_datetime <= ?)", @startdate, (@startdate + @preg_range)])
    
  end


  def syphilis_result_pos
    # Encounter.find(:all, :joins => [:observations], :group => ["patient_id"], :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"], :conditions => ["concept_id = ? AND value_coded = ?", ConceptName.find_by_name("Syphilis Test Result").concept, ConceptName.find_by_name("Not done").concept_id])

    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Syphilis Test Result").concept_id,
        ConceptName.find_by_name("Positive").concept_id, "Positive",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def syphilis_result_neg
		
    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Syphilis Test Result").concept_id,
        ConceptName.find_by_name("Negative").concept_id, "Negative",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def syphilis_result_unk
		
    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Syphilis Test Result").concept_id,
        ConceptName.find_by_name("Not Done").concept_id, "Not Done",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def hiv_test_result_prev_neg
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Negative").concept_id, "Negative",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.form_id}
   
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')",
        ConceptName.find_by_name("HIV test date").concept_id,
        select, @cohortpatients]).collect{|e| e.patient_id}
  
  end


  def hiv_test_result_prev_pos
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Positive").concept_id, "Positive",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')",
        ConceptName.find_by_name("HIV test date").concept_id,
        select, @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def hiv_test_result_neg
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Negative").concept_id, "Negative",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')",
        ConceptName.find_by_name("HIV test date").concept_id,
        select, @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def hiv_test_result_pos
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Positive").concept_id, "Positive",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.form_id}
    
    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
          "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')",
        ConceptName.find_by_name("HIV test date").concept_id,
        select, @cohortpatients]).collect{|e| e.patient_id}
    
  end


  def hiv_test_result_unk
		
    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Not done").concept_id, "Not Done",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
    
  end

  def not_on_art
    
    local =  Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"],
      :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("HIV status").concept_id,
        ConceptName.find_by_name("Positive").concept_id, "Positive",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
  
    no_art = local - on_art_before
    no_art = no_art.uniq
    no_art = [] if no_art.to_s.blank?
    return no_art
    
  end

  def on_art_before
    
    #patients = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
    # :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"],
    # :conditions => ["concept_id = ? AND value_text = ? AND (encounter_datetime >= ? " +
    #    "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
    # ConceptName.find_by_name("Date Antiretrovirals Started").concept_id,
    # "Before This Pregnancy",
    # @startdate, @end_date, @cohortpatients]).collect{|e| e.patient_id}  rescue []
    ids = @bart_patient_identifiers.collect{|id| PatientIdentifier.find_by_identifier(id).patient_id}.uniq rescue []
    return ids
  end

  def on_art_zero_to_27
    
    local =	Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"],
      :conditions => ["concept_id = ? AND value_text = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Date Antiretrovirals Started").concept_id,
        "At 0-27 weeks of Pregnancy",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id} rescue []
        
    @art_ids = "'" + @bart_patient_identifiers.join("','") + "'"
    
    remote =   Observation.find_by_sql("SELECT p.identifier, o.value_datetime, o.person_id FROM obs o
			JOIN patient_identifier p ON p.patient_id = o.person_id
			WHERE o.concept_id = (SELECT concept_id FROM concept_name WHERE name = 'LAST MENSTRUAL PERIOD')
			AND p.identifier IN (#{@art_ids})").collect{|ob|
      ident = ob.identifier
      if (!ob.value_datetime.blank? && @bart_patients["#{ident}"])
        check = (@bart_patients["#{ident}"].to_date - (ob.value_datetime.to_date + 7.days)).days
        ob.person_id if (check <= (27*7).days && check >= 0.days)
      end
    } rescue []
    remote = remote.concat(local).uniq
    remote = [] if remote.to_s.blank?
    return remote
    
  end

  def on_art_28_plus
    
    local  = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
      :select => ["patient_id, MAX(encounter_datetime) encounter_datetime"],
      :conditions => ["concept_id = ? AND value_text = ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Date Antiretrovirals Started").concept_id,
        "At 28+ of Pregnancy",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id} rescue []

    @art_ids = "'" + @bart_patient_identifiers.join("','") + "'"
    remote =   Observation.find_by_sql("SELECT p.identifier, o.value_datetime, o.person_id FROM obs o
			JOIN patient_identifier p ON p.patient_id = o.person_id
			WHERE o.concept_id = (SELECT concept_id FROM concept_name WHERE name = 'LAST MENSTRUAL PERIOD')
			AND p.identifier IN (#{@art_ids})").collect{|ob|
      ident = ob.identifier
      if (!ob.value_datetime.blank? && @bart_patients["#{ident}"])
        ob.person_id if (@bart_patients["#{ident}"].to_date - (ob.value_datetime.to_date + 7.days)).days > (27*7).days
      end
    } rescue []
    remote = remote.concat(local).uniq
    remote = [] if remote.to_s.blank?
    return remote
  end

  def on_cpt__1
    ids = @on_cpt.split(",").collect{|id| PatientIdentifier.find_by_identifier(id).patient_id}.uniq rescue []
    return ids
  end

  def nvp_baby__1

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
          "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id],
      :conditions => ["drug.name LIKE ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "NVP%ml%",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o| o.patient_id}
    
  end

  def albendazole
    
    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
          "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id],
      :conditions => ["drug.name REGEXP ? AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)", "Albendazole",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|o|
      [o.patient_id, o.orderer]
    }.delete_if{|x,y| y != 1}.collect{|p, c| p}
    
  end
  
  def bed_net
    
    Encounter.find(:all, :joins => [:observations],
      :conditions => ["concept_id = ? AND (value_text = ?) AND (encounter_datetime >= ? " +
          "AND encounter_datetime <= ?) AND encounter.patient_id IN (?)",
        ConceptName.find_by_name("Bed Net").concept_id, "Given Today",
        @startdate, (@startdate.to_date + @preg_range), @cohortpatients]).collect{|e| e.patient_id}
    
  end
  
  def on_art_in_bart
    national_id = PatientIdentifierType.find_by_name("National id").id
    patient_ids = PatientIdentifier.find(:all, :select => ['identifier, identifier_type'], :conditions => ["identifier_type = ? AND patient_id IN (?)", 		national_id, @cohortpatients]).collect{|ident|
      ident.identifier}.join(",")
    id_visit_map = []
    patient_ids.split(",").each do |id|
      next if id.nil?
      patient_id = PatientIdentifier.find_by_identifier(id).patient_id
      if patient_id
        date = Observation.find_by_sql("SELECT * FROM obs where person_id = #{patient_id} 
                AND concept_id = (SELECT concept_id FROM concept_name where name = 'TYPE OF VISIT'
                 AND value_numeric = 1 order by date_created LIMIT 1)").first.date_created.strftime("%Y-%m-%d") rescue nil
            
        value = "" + id + "|" + date   if !date.nil?
        id_visit_map << value if !date.nil?
      end

    end
    
    paramz = Hash.new
    paramz["ids"] = patient_ids
    paramz["start_date"] = @startdate.to_date 
    paramz["end_date"] = @startdate.to_date + @preg_range
    paramz["id_visit_map"] = id_visit_map.join(",")

    server = CoreService.get_global_property_value("remote_servers.parent")

    login = CoreService.get_global_property_value("remote_bart.username").split(/,/) rescue ""
    password = CoreService.get_global_property_value("remote_bart.password").split(/,/) rescue ""
				
    uri = "http://#{login}:#{password}@#{server}/encounters/export_on_art_patients"
    patient_identifiers = JSON.parse(RestClient.post(uri, paramz)) rescue {}
    
    return patient_identifiers
  end
end
