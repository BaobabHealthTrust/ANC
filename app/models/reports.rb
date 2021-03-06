# app/models/report.rb

class Reports

  # Initialize class
  def initialize(start_date, end_date, start_age, end_age, type, today=Date.today)

    @today = end_date.to_date
    @type = type
    @type = "cohort" if @type.blank?
    start_date = (@type == 'cohort') ? (start_date.to_date - 6.months) : start_date
    end_date = (@type == 'cohort') ? (end_date.to_date - 6.months) : end_date
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"
    @start_age = start_age
    @end_age = end_age

    @enddate = @end_date
    @startdate = @start_date

    @preg_range = (@type == "cohort") ? 6.months : ((end_date.to_time - start_date.to_time).round/(3600*24)).days

    if @type == "cohort"

      @cohortpatients = registrations(@startdate.to_date.beginning_of_month, @enddate.to_date.end_of_month)

    else

      @cohortpatients = Encounter.find(:all, :joins => [:observations], :group => [:patient_id],
                                       :select => ["patient_id"],
                                       :conditions => ["encounter_type = ? AND concept_id = ? AND encounter_datetime >= ? " +
                                                           "AND encounter_datetime <= ? AND encounter.voided = 0",
                                                       EncounterType.find_by_name("ANC VISIT TYPE").id,
                                                       ConceptName.find_by_name("TYPE OF VISIT").concept_id,
                                                       @startdate, @enddate]).collect { |e| e.patient_id }.uniq

    end

    e_date = (@startdate.to_date + @preg_range).to_date
    min_date = @startdate.to_date - 10.months

    lmp_concept = ConceptName.find_by_name("DATE OF LAST MENSTRUAL PERIOD").concept_id

    lmp = "(SELECT DATE(MAX(o.value_datetime)) FROM obs o WHERE o.person_id = enc.patient_id
            AND o.concept_id = #{lmp_concept} AND DATE(o.obs_datetime) <= '#{e_date.to_s}'
            AND DATE(o.obs_datetime) >= '#{min_date.to_s}')"

    @anc_visits = Encounter.find_by_sql(["SELECT #{lmp} lmp, enc.patient_id patient_id, MAX(ob.value_numeric) form_id FROM encounter enc
                                        INNER JOIN obs ob ON ob.encounter_id = enc.encounter_id
                                        WHERE enc.patient_id IN (?) AND enc.encounter_type = ?
                                        AND ob.concept_id = ? AND DATE(enc.encounter_datetime) <= ?
                                        AND DATE(enc.encounter_datetime) >= #{lmp}
                                        GROUP BY enc.patient_id",
                                       @cohortpatients,
                                       EncounterType.find_by_name("ANC VISIT TYPE").id,
                                       ConceptName.find_by_name("Reason for visit").concept_id,
                                       e_date
                                      ]).collect { |e| [e.patient_id, e.form_id] }

    @positive_patients = (hiv_test_result_pos.uniq + hiv_test_result_prev_pos.uniq).delete_if { |p| p.blank? }

    @bart_patients = on_art_in_bart

    @on_cpt = @bart_patients['on_cpt']
    @no_art = @bart_patients['no_art']
    @on_art_before = @bart_patients['arv_before_visit_one']

    @bart_patients.delete("on_cpt")
    @bart_patients.delete("arv_before_visit_one")
    @bart_patients.delete("no_art")
    @bart_patient_identifiers = @bart_patients.keys
  end

  def registrations(start_dt, end_dt)

    Encounter.find(:all, :joins => [:observations], :group => [:patient_id],
                   :select => ["MAX(value_datetime) lmp, patient_id"],
                   :conditions => ["encounter_type = ? AND concept_id = ? AND DATE(encounter_datetime) >= ? " +
                                       "AND DATE(encounter_datetime) <= ? AND encounter.voided = 0",
                                   EncounterType.find_by_name("Current Pregnancy").id,
                                   ConceptName.find_by_name("Date of Last Menstrual Period").concept_id,
                                   start_dt.to_date, end_dt.to_date]).collect { |e| e.patient_id }.uniq

  end

  def new_women_registered

    if @type == "cohort"

      registrations(@today.beginning_of_month, @today.end_of_month)

    else

      registrations(@startdate, @enddate)

    end

  end

  def observations_total

    @anc_visits.collect { |x, y| x if y.present? }.uniq
  end

  def observations_1

    @anc_visits.reject { |x, y| y != 1 }.collect { |x, y| x }.uniq
  end

  def observations_2

    @anc_visits.reject { |x, y| y != 2 }.collect { |x, y| x }.uniq
  end

  def observations_3

    @anc_visits.reject { |x, y| y != 3 }.collect { |x, y| x }.uniq
  end


  def observations_4

    @anc_visits.reject { |x, y| y != 4 }.collect { |x, y| x }.uniq
  end


  def observations_5

    @anc_visits.reject { |x, y| y < 5 }.collect { |x, y| x }.uniq
  end


  def week_of_first_visit_1

    @cases = Encounter.find(:all, :joins => [:observations],
                            :conditions => ["concept_id = ? AND value_numeric < 13 AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
                                                " AND patient_id IN (?)",
                                            ConceptName.find_by_name("WEEK OF FIRST VISIT").concept_id,
                                            @start_date.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }.uniq

    @cases
  end


  def week_of_first_visit_2

    @cases = Encounter.find(:all, :joins => [:observations],
                            :conditions => ["concept_id = ? AND value_numeric >= 13 AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
                                                " AND patient_id IN (?)",
                                            ConceptName.find_by_name("WEEK OF FIRST VISIT").concept_id,
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }.uniq

    @cases
  end


  def pre_eclampsia_2

    Encounter.find(:all, :joins => [:observations],
                   :conditions => ["concept_id = ? AND value_coded = ? AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
                                       "AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("DIAGNOSIS").concept_id, ConceptName.find_by_name("PRE-ECLAMPSIA").concept_id,
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }.uniq

  end


  def pre_eclampsia_1

    @cases1 = Encounter.find(:all, :joins => [:observations],
                             :conditions => ["concept_id = ? AND value_coded IN (?) AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
                                                 "AND encounter.patient_id IN (?)",

                                             ConceptName.find_by_name("DIAGNOSIS").concept_id,
                                             ["ECLAMPSIA", "PRE-ECLAMPSIA"].collect { |name| ConceptName.find_by_name(name).concept_id },
                                             @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }.uniq

    @cases2 = Patient.find_by_sql(["SELECT * FROM patient WHERE patient_id IN " +
                                       "(SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = " +
                                       "obs.encounter_id WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name REGEXP 'ECLAMPSIA') " +
                                       "AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'YES') OR " +
                                       "value_text = 'YES') AND " +
                                       "DATE(encounter_datetime) >= ? AND DATE(encounter_datetime) <= ?) AND patient_id IN (?)", @startdate.to_date, (@startdate.to_date - @preg_range).to_date, @cohortpatients]).collect { |cas| cas.patient_id }

    @cases = (@cases1 + @cases2).uniq

  end


  def ttv__total_previous_doses_1

    @cases = Patient.find_by_sql(["SELECT * FROM patient WHERE patient_id IN (SELECT person_id FROM obs LEFT OUTER JOIN encounter ON encounter.encounter_id = obs.encounter_id WHERE concept_id = (SELECT concept_id FROM concept_name WHERE name = 'TTV: TOTAL PREVIOUS DOSES') AND (value_coded IN (SELECT concept_id FROM concept_name WHERE name = '=0 OR =1') OR value_numeric = '=0 OR =1' OR value_boolean = '=0 OR =1' OR value_datetime = '=0 OR =1' OR value_text = '=0 OR =1') AND encounter_datetime >= ? AND encounter_datetime <= ?)", @startdate, (@startdate.to_date + @preg_range)]).collect { |p| p.patient_id }.uniq

  end

  def ttv__total_previous_doses_2(tag = 2)
    patients = {}

    if tag == 1
      return (@cohortpatients - ttv__total_previous_doses_2(2)).uniq
    end

    Encounter.find(:all, :joins => [:observations],
                   :select => ["patient_id, (COALESCE(value_numeric,0)+COALESCE(value_text,0)) form_id"],
                   :conditions => ["concept_id = ? AND (value_numeric > 0 OR value_text > 0) AND DATE(encounter_datetime) BETWEEN (?) AND (?)" +
                                       "AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("TT STATUS").concept_id,
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).each { |e|
      patients[e.patient_id] = e.form_id };

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id"],
               :group => [:patient_id], :conditions => ["drug.name LIKE ? AND (DATE(encounter_datetime) >= ? " +
                                                            "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?) AND orders.voided = 0", "%TTV%",
                                                        @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.encounter_id] }.delete_if { |p, e|
      v = 0;
      v = patients[p] if patients[p]
      v.to_i + e.to_i < 2
    }.collect { |x, y| x }.uniq

  end


  def fansida__sp___number_of_tablets_given_0

    select = Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
                        :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
                        :group => [:patient_id], :conditions => ["drug.name = ? AND (DATE(encounter_datetime) >= ? " +
                                                                     "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
                                                                 @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o| o.patient_id }

    @cohortpatients - select

  end

  def fansida__sp___number_of_tablets_given_1

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
               :group => [:patient_id], :conditions => ["drug.name = ? AND (DATE(encounter_datetime) >= ? " +
                                                            "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
                                                        @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.encounter_id]
    }.delete_if { |x, y| y != 1 }.collect { |p, c| p }

  end


  def fansida__sp___number_of_tablets_given_2

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions"],
               :group => [:patient_id], :conditions => ["drug.name = ? AND (DATE(encounter_datetime) >= ? " +
                                                            "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "SP (3 tablets)",
                                                        @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.encounter_id]
    }.delete_if { |x, y| y != 2 }.collect { |p, c| p }

  end


  def fefo__number_of_tablets_given_1

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
                               "COALESCE(SUM(DATEDIFF(auto_expire_date, start_date)), 0) orderer"], :group => [:patient_id],
               :conditions => ["drug.name = ? AND (DATE(encounter_datetime) >= ? " +
                                   "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "Fefol (1 tablet)",
                               @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.orderer] }.delete_if { |x, y| y >= 120 }.collect { |p, c| p }

  end


  def fefo__number_of_tablets_given_2

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
                               "COALESCE(SUM(DATEDIFF(auto_expire_date, start_date)), 0) orderer"], :group => [:patient_id],
               :conditions => ["drug.name = ? AND (DATE(encounter_datetime) >= ? " +
                                   "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "Fefol (1 tablet)",
                               @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.orderer] }.delete_if { |x, y| y < 120 }.collect { |p, c| p }

  end


  def syphilis_result_pos

    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
                   :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                       "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("Syphilis Test Result").concept_id,
                                   ConceptName.find_by_name("Positive").concept_id, "Positive",
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }
  end


  def syphilis_result_neg

    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
                   :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                       "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("Syphilis Test Result").concept_id,
                                   ConceptName.find_by_name("Negative").concept_id, "Negative",
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }
  end


  def syphilis_result_unk

    Encounter.find(:all, :joins => [:observations], :select => ["DISTINCT patient_id"],
                   :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                       "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("Syphilis Test Result").concept_id,
                                   ConceptName.find_by_name("Not Done").concept_id, "Not Done",
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }

  end


  def hiv_test_result_prev_neg

    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                            :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
                            :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                                "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                            ConceptName.find_by_name("HIV status").concept_id,
                                            ConceptName.find_by_name("Negative").concept_id, "Negative",
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.form_id }

    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                   :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
                                       "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')",
                                   ConceptName.find_by_name("HIV test date").concept_id,
                                   select, @cohortpatients]).collect { |e| e.patient_id }

  end


  def hiv_test_result_prev_pos

    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                            :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
                            :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                                "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                            ConceptName.find_by_name("HIV status").concept_id,
                                            ConceptName.find_by_name("Positive").concept_id, "Positive",
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.form_id }

    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                   :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
                                       "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') > DATE_FORMAT(value_datetime, '%Y-%m-%d')",
                                   ConceptName.find_by_name("HIV test date").concept_id,
                                   select, @cohortpatients]).collect { |e| e.patient_id }

  end


  def hiv_test_result_neg

    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                            :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
                            :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                                "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                            ConceptName.find_by_name("HIV status").concept_id,
                                            ConceptName.find_by_name("Negative").concept_id, "Negative",
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.form_id }

    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                   :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
                                       "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')",
                                   ConceptName.find_by_name("HIV test date").concept_id,
                                   select, @cohortpatients]).collect { |e| e.patient_id }

  end


  def hiv_test_result_pos

    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                            :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
                            :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                                "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                            ConceptName.find_by_name("HIV status").concept_id,
                                            ConceptName.find_by_name("Positive").concept_id, "Positive",
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.form_id }

    Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                   :conditions => ["concept_id = ? AND obs_id IN (?) AND encounter.patient_id IN (?) AND " +
                                       "DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = DATE_FORMAT(value_datetime, '%Y-%m-%d')",
                                   ConceptName.find_by_name("HIV test date").concept_id,
                                   select, @cohortpatients]).collect { |e| e.patient_id }

  end


  def hiv_test_result_unk

    select = Encounter.find(:all, :joins => [:observations], :group => ["patient_id"],
                            :select => ["patient_id, MAX(encounter_datetime) encounter_datetime, (obs_id + 1) form_id"],
                            :conditions => ["concept_id = ? AND (value_coded = ? OR value_text = ?) AND (DATE(encounter_datetime) >= ? " +
                                                "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                            ConceptName.find_by_name("HIV status").concept_id,
                                            ConceptName.find_by_name("Not done").concept_id, "Not Done",
                                            @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }

  end

  def not_on_art(hiv_patients = [])

    no_art = @no_art.split(",").collect { |id|
      PatientIdentifier.find_by_identifier(id).patient_id }.uniq rescue []
    return no_art
  end

  def on_art_before

    ids =  @on_art_before.split(",").collect { |id|
      PatientIdentifier.find_by_identifier(id).patient_id }.uniq rescue []
    return ids
  end

  def on_art_zero_to_27

    remote = []
    Observation.find_by_sql(["SELECT p.identifier, o.value_datetime, o.person_id FROM obs o
			JOIN patient_identifier p ON p.patient_id = o.person_id
			WHERE o.concept_id = (SELECT concept_id FROM concept_name WHERE name = 'LAST MENSTRUAL PERIOD')
			AND p.patient_id IN (?) AND DATE(o.obs_datetime) BETWEEN ? AND ?",
                                      @positive_patients, @startdate.to_date, (@startdate.to_date + @preg_range)]).collect { |ob|
      ident = ob.identifier
      if (!ob.value_datetime.blank? && @bart_patients["#{ident}"])
        start_date = @bart_patients["#{ident}"].to_date
        lmp = ob.value_datetime.to_date
        remote << ob.person_id if  ((start_date >= lmp) && (start_date < (lmp + 28.weeks)))
      end
    }# rescue []

    remote = [] if remote.to_s.blank?
    return remote

  end

  def on_art_28_plus

    remote = []
     Observation.find_by_sql(["SELECT p.identifier, o.value_datetime, o.person_id FROM obs o
			JOIN patient_identifier p ON p.patient_id = o.person_id
			WHERE o.concept_id = (SELECT concept_id FROM concept_name WHERE name = 'LAST MENSTRUAL PERIOD')
			AND p.patient_id IN (?) AND DATE(o.obs_datetime) BETWEEN ? AND ?",
                                        @positive_patients, @startdate.to_date, (@startdate.to_date + @preg_range)]).each { |ob|
      ident = ob.identifier
      if (!ob.value_datetime.blank? && @bart_patients["#{ident}"])
        start_date = @bart_patients["#{ident}"].to_date
        lmp = ob.value_datetime.to_date
        remote << ob.person_id if  (start_date >= (lmp + 28.weeks))
      end
    } rescue []

    remote = [] if remote.to_s.blank?
    return remote
  end

  def on_cpt__1
    ids = @on_cpt.split(",").collect { |id| PatientIdentifier.find_by_identifier(id.gsub(/\-|\s+/, "")).patient_id }.uniq rescue []
    return ids
  end

  def nvp_baby__1

    Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
               :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
                               "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id],
               :conditions => ["(drug.name REGEXP ? OR drug.name REGEXP ?)  AND drug.name REGEXP ? AND (DATE(encounter_datetime) >= ? " +
                                   "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "NVP", "Nevirapine", "ml",
                               @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o| o.patient_id }

  end

  def albendazole(qty = 1)
    result = []

    data = Order.find(:all, :joins => [[:drug_order => :drug], :encounter],
                      :select => ["encounter.patient_id, count(*) encounter_id, drug.name instructions, " +
                                      "SUM(DATEDIFF(auto_expire_date, start_date)) orderer"], :group => [:patient_id],
                      :conditions => ["drug.name REGEXP ? AND (DATE(encounter_datetime) >= ? " +
                                          "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)", "Albendazole",
                                      @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |o|
      [o.patient_id, o.orderer]
    }

    if qty == 1
      result = data.delete_if { |x, y| y != 1 }.collect { |p, c| p }
    elsif qty == ">1"
      result = data.delete_if { |x, y| y <= 1 }.collect { |p, c| p }
    elsif qty == "<1"
      result = data.delete_if { |x, y| y >= 1 }.collect { |p, c| p }
    end
    result
  end

  def bed_net

    Encounter.find(:all, :joins => [:observations],
                   :conditions => ["concept_id = ? AND (value_text = ?) AND ( DATE(encounter_datetime) >= ? " +
                                       "AND DATE(encounter_datetime) <= ?) AND encounter.patient_id IN (?)",
                                   ConceptName.find_by_name("Bed Net").concept_id, "Given Today",
                                   @startdate.to_date, (@startdate.to_date + @preg_range), @cohortpatients]).collect { |e| e.patient_id }

  end

  def on_art_in_bart

    national_id = PatientIdentifierType.find_by_name("National id").id
    patient_ids = PatientIdentifier.find(:all, :select => ['identifier, identifier_type'],
                                         :conditions => ["identifier_type = ? AND patient_id IN (?)", national_id,
                                                         @positive_patients]).collect { |ident|
      ident.identifier }.join(",")
    id_visit_map = []
    patient_ids.split(",").each do |id|
      next if id.nil?
      patient_id = PatientIdentifier.find_by_identifier(id).patient_id
      if patient_id
        date = Observation.find_by_sql(["SELECT value_datetime FROM obs WHERE person_id = ?
                                        AND DATE(obs_datetime) BETWEEN ? AND ? AND concept_id = ?",
                                       patient_id,  @startdate.to_date, (@startdate.to_date + @preg_range),
                                       ConceptName.find_by_name("DATE OF LAST MENSTRUAL PERIOD").concept_id]).first.value_datetime.strftime("%Y-%m-%d") rescue nil

        value = "" + id + "|" + date if !date.nil?
        id_visit_map << value if !date.nil?
      end

    end

    paramz = Hash.new
    paramz["ids"] = patient_ids
    paramz["start_date"] = @startdate.to_date
    paramz["end_date"] = @startdate.to_date + @preg_range
    paramz["id_visit_map"] = id_visit_map.join(",")

    server = CoreService.get_global_property_value("art_link")

    login = CoreService.get_global_property_value("remote_bart.username").split(/,/) rescue ""
    password = CoreService.get_global_property_value("remote_bart.password").split(/,/) rescue ""

    uri = "http://#{login}:#{password}@#{server}/encounters/export_on_art_patients"
    patient_identifiers = JSON.parse(RestClient.post(uri, paramz)) rescue {}

    return patient_identifiers
  end
end
