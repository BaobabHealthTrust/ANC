class Patient < ActiveRecord::Base
  set_table_name "patient"
  set_primary_key "patient_id"
  include Openmrs

  has_one :person, :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :visits, :dependent => :destroy, :conditions => 'visit.voided = 0'
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :orders, :conditions => {:voided => 0}
  has_many :encounters, :conditions => {:voided => 0} do 
    def find_by_date(encounter_date)
      encounter_date = Date.today unless encounter_date
      find(:all, :conditions => ["DATE(encounter_datetime) = DATE(?)", encounter_date]) # Use the SQL DATE function to compare just the date part
    end
  end

  def after_void(reason = nil)
    self.person.void(reason) rescue nil
    self.patient_identifiers.each {|row| row.void(reason) }
    self.patient_programs.each {|row| row.void(reason) }
    self.orders.each {|row| row.void(reason) }
    self.encounters.each {|row| row.void(reason) }
  end

  def current_diagnoses
    self.encounters.current.all(:include => [:observations]).map{|encounter| 
      encounter.observations.all(
        :conditions => ["obs.concept_id = ? OR obs.concept_id = ?", 
          ConceptName.find_by_name("DIAGNOSIS").concept_id,
          ConceptName.find_by_name("DIAGNOSIS, NON-CODED").concept_id])
    }.flatten.compact
  end

  def current_treatment_encounter(date = Time.now())
    type = EncounterType.find_by_name("TREATMENT")
    encounter = encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= encounters.create(:encounter_type => type.id,:encounter_datetime => date)
  end

  def current_dispensation_encounter(date = Time.now())
    type = EncounterType.find_by_name("DISPENSING")
    encounter = encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= encounters.create(:encounter_type => type.id,:encounter_datetime => date)
  end
    
  def alerts
    # next appt
    # adherence
    # drug auto-expiry
    # cd4 due    
  end
  
  def summary
    #    verbiage << "Last seen #{visits.recent(1)}"
    verbiage = []
    verbiage << patient_programs.map{|prog| "Started #{prog.program.name.humanize} #{prog.date_enrolled.strftime('%b-%Y')}" rescue nil }
    verbiage << orders.unfinished.prescriptions.map{|presc| presc.to_s}
    verbiage.flatten.compact.join(', ') 
  end

  def national_id(force = true)
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => self).identifier
    id
  end

  def national_id_with_dashes(force = true)
    id = self.national_id(force)
    id[0..4] + "-" + id[5..8] + "-" + id[9..-1] rescue id
  end

  def national_id_label
    return unless self.national_id
    sex =  self.person.gender.match(/F/i) ? "(F)" : "(M)"
    address = self.person.address.strip[0..24].humanize.delete("'") rescue ""
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 2
    label.font_vertical_multiplier = 2
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{self.national_id}")
    label.draw_multi_text("#{self.person.name.titleize.delete("'")}") #'
    label.draw_multi_text("#{self.national_id_with_dashes} #{self.person.birthdate_formatted}#{sex}")
    label.draw_multi_text("#{address}")
    label.print(1)
  end
  
  def visit_label(date = Date.today)
    label = ZebraPrinter::StandardLabel.new
    label.font_size = 3
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 50
    encs = encounters.find(:all,:conditions =>["DATE(encounter_datetime) = ?",date])
    return nil if encs.blank?
    
    label.draw_multi_text("Visit: #{encs.first.encounter_datetime.strftime("%d/%b/%Y %H:%M")}", :font_reverse => true)    
    encs.each {|encounter|
      next if encounter.name.humanize == "Registration"
      label.draw_multi_text("#{encounter.name.humanize}: #{encounter.to_s}", :font_reverse => false)
    }
    label.print(1)
  end
  
  def get_identifier(type = 'National id')
    identifier_type = PatientIdentifierType.find_by_name(type)
    return if identifier_type.blank?
    identifiers = self.patient_identifiers.find_all_by_identifier_type(identifier_type.id)
    return if identifiers.blank?
    identifiers.map{|i|i.identifier}.join(' , ') rescue nil
  end
  
  def current_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.first.value_numeric rescue 0
  end
  
  def current_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.first.value_numeric rescue 0
  end
  
  def initial_weight
    obs = person.observations.recent(1).question("WEIGHT (KG)").all
    obs.last.value_numeric rescue 0
  end
  
  def initial_height
    obs = person.observations.recent(1).question("HEIGHT (CM)").all
    obs.last.value_numeric rescue 0
  end

  def initial_bmi
    obs = person.observations.recent(1).question("BMI").all
    obs.last.value_numeric rescue nil
  end

  def min_weight
    WeightHeight.min_weight(person.gender, person.age_in_months).to_f
  end
  
  def max_weight
    WeightHeight.max_weight(person.gender, person.age_in_months).to_f
  end
  
  def min_height
    WeightHeight.min_height(person.gender, person.age_in_months).to_f
  end
  
  def max_height
    WeightHeight.max_height(person.gender, person.age_in_months).to_f
  end
  
  def given_arvs_before?
    self.orders.each{|order|
      drug_order = order.drug_order
      next if drug_order == nil
      next if drug_order.quantity == nil
      next unless drug_order.quantity > 0
      return true if drug_order.drug.arv?
    }
    false
  end

  def name
    "#{self.person.name}"
  end

  def self.dead_with_visits(start_date, end_date)
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    patient_died_concept    = ConceptName.find_by_name('PATIENT DIED').concept_id

    dead_patients = "SELECT dead_patient_program.patient_program_id,
    dead_state.state, dead_patient_program.patient_id, dead_state.date_changed
    FROM patient_state dead_state INNER JOIN patient_program dead_patient_program
    ON   dead_state.patient_program_id = dead_patient_program.patient_program_id
    WHERE  EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE dead_state.state = program_workflow_state_id AND concept_id = #{patient_died_concept})
          AND dead_state.date_changed >='#{start_date}' AND dead_state.date_changed <= '#{end_date}'"

    living_patients = "SELECT living_patient_program.patient_program_id,
    living_state.state, living_patient_program.patient_id, living_state.date_changed
    FROM patient_state living_state
    INNER JOIN patient_program living_patient_program
    ON living_state.patient_program_id = living_patient_program.patient_program_id
    WHERE  NOT EXISTS
      (SELECT * FROM program_workflow_state p
        WHERE living_state.state = program_workflow_state_id AND concept_id =  #{patient_died_concept})"

    dead_patients_with_observations_visits = "SELECT death_observations.person_id,death_observations.obs_datetime AS date_of_death, active_visits.obs_datetime AS date_living
    FROM obs active_visits INNER JOIN obs death_observations
    ON death_observations.person_id = active_visits.person_id
    WHERE death_observations.concept_id != active_visits.concept_id AND death_observations.concept_id =  #{patient_died_concept} AND death_observations.obs_datetime < active_visits.obs_datetime
      AND death_observations.obs_datetime >='#{start_date}' AND death_observations.obs_datetime <= '#{end_date}'"

    all_dead_patients_with_visits = " SELECT dead.patient_id, dead.date_changed AS date_of_death, living.date_changed
    FROM (#{dead_patients}) dead,  (#{living_patients}) living
    WHERE living.patient_id = dead.patient_id AND dead.date_changed < living.date_changed
    UNION ALL #{dead_patients_with_observations_visits}"

    patients = self.find_by_sql([all_dead_patients_with_visits])
    patients_data  = []
    patients.each do |patient_data_row|
      patient        = Person.find(patient_data_row[:patient_id].to_i)
      national_id    = PatientIdentifier.identifier(patient_data_row[:patient_id], national_identifier_id).identifier rescue ""
      arv_number     = PatientIdentifier.identifier(patient_data_row[:patient_id], arv_number_id).identifier rescue ""
      patients_data <<[patient_data_row[:patient_id], arv_number, patient.name,
        national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:date_changed]]
    end
    patients_data
  end

  def self.males_allegedly_pregnant(start_date, end_date)
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    pregnant_patient_concept_id = ConceptName.find_by_name('PATIENT PREGNANT').concept_id

    patients = PatientIdentifier.find_by_sql(["SELECT person.person_id,obs.obs_datetime
                                   FROM obs INNER JOIN person
                                   ON obs.person_id = person.person_id
                                   WHERE person.gender = 'M' AND
                                   obs.concept_id = ? AND obs.obs_datetime >= ? AND obs.obs_datetime <= ?",
        pregnant_patient_concept_id, '2008-12-23 00:00:00', end_date])

    patients_data  = []
    patients.each do |patient_data_row|
      patient        = Person.find(patient_data_row[:person_id].to_i)
      national_id    = PatientIdentifier.identifier(patient_data_row[:person_id], national_identifier_id).identifier rescue ""
      arv_number     = PatientIdentifier.identifier(patient_data_row[:person_id], arv_number_id).identifier rescue ""
      patients_data <<[patient_data_row[:person_id], arv_number, patient.name,
        national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:obs_datetime]]
    end
    patients_data
  end

  def self.with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)

    arv_drugs_concepts      = Drug.arv_drugs.inject([]) {|result, drug| result << drug.concept_id}
    on_arv_concept_id       = ConceptName.find_by_name('ON ANTIRETROVIRALS').concept_id
    hvi_program_id          = Program.find_by_name('HIV PROGRAM').program_id
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id

    patients_on_antiretrovirals_sql = "
         (SELECT p.patient_id, s.date_created as Date_Started_ARV
          FROM patient_program p INNER JOIN patient_state s
          ON  p.patient_program_id = s.patient_program_id
          WHERE s.state IN (SELECT program_workflow_state_id
                            FROM program_workflow_state g
                            WHERE g.concept_id = #{on_arv_concept_id})
                            AND p.program_id = #{hvi_program_id}
         ) patients_on_antiretrovirals"

    antiretrovirals_obs_sql = "
         (SELECT * FROM obs
          WHERE  value_drug IN (SELECT drug_id FROM drug
          WHERE concept_id IN ( #{arv_drugs_concepts.join(', ')} ) )
         ) antiretrovirals_obs"

    drug_start_dates_less_than_program_enrollment_dates_sql= "
      SELECT patients_on_antiretrovirals.patient_id, patients_on_antiretrovirals.date_started_ARV,
             antiretrovirals_obs.obs_datetime, antiretrovirals_obs.value_drug
      FROM #{patients_on_antiretrovirals_sql}, #{antiretrovirals_obs_sql}
      WHERE patients_on_antiretrovirals.Date_Started_ARV > antiretrovirals_obs.obs_datetime
            AND patients_on_antiretrovirals.patient_id = antiretrovirals_obs.person_id
            AND patients_on_antiretrovirals.Date_Started_ARV >='#{start_date}' AND patients_on_antiretrovirals.Date_Started_ARV <= '#{end_date}'"

    patients       = self.find_by_sql(drug_start_dates_less_than_program_enrollment_dates_sql)
    patients_data  = []
    patients.each do |patient_data_row|
      patient     = Person.find(patient_data_row[:patient_id].to_i)
      national_id = PatientIdentifier.identifier(patient_data_row[:patient_id], national_identifier_id).identifier rescue ""
      arv_number  = PatientIdentifier.identifier(patient_data_row[:patient_id], arv_number_id).identifier rescue ""
      patients_data <<[patient_data_row[:patient_id], arv_number, patient.name,
        national_id,patient.gender,patient.age,patient.birthdate, patient.phone_numbers, patient_data_row[:date_started_ARV]]
    end
    patients_data
  end

  def self.appointment_dates(start_date, end_date = nil)

    end_date = start_date if end_date.nil?

    appointment_date_concept_id = Concept.find_by_name("APPOINTMENT DATE").concept_id rescue nil

    appointments = Patient.find(:all,
      :joins      => 'INNER JOIN obs ON patient.patient_id = obs.person_id',
      :conditions => ["DATE(obs.value_datetime) >= ? AND DATE(obs.value_datetime) <= ? AND obs.concept_id = ? AND obs.voided = 0", start_date.to_date, end_date.to_date, appointment_date_concept_id],
      :group      => "obs.person_id")

    appointments
  end

  def arv_number
    arv_number_id = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    PatientIdentifier.identifier(self.patient_id, arv_number_id).identifier rescue nil
  end

  def age_at_initiation(initiation_date)
    patient = Person.find(self.id)
    return patient.age(initiation_date) unless initiation_date.nil?
  end

  def set_received_regimen(encounter,order)
    dispense_finish = true ; dispensed_drugs_concept_ids = []
    
    ( order.encounter.orders || [] ).each do | order |
      dispense_finish = false if order.drug_order.amount_needed > 0
      dispensed_drugs_concept_ids << Drug.find(order.drug_order.drug_inventory_id).concept_id
    end

    return unless dispense_finish

    regimen_id = ActiveRecord::Base.connection.select_value <<EOF
SELECT concept_id FROM drug_ingredient 
WHERE ingredient_id IN (SELECT distinct ingredient_id 
FROM drug_ingredient 
WHERE concept_id IN (#{dispensed_drugs_concept_ids.join(',')}))
GROUP BY concept_id
HAVING COUNT(*) = (SELECT COUNT(distinct ingredient_id) 
FROM drug_ingredient 
WHERE concept_id IN (#{dispensed_drugs_concept_ids.join(',')}))
EOF
  
    regimen_prescribed = regimen_id.to_i rescue ConceptName.find_by_name('UNKNOWN ANTIRETROVIRAL DRUG').concept_id
    
    if (Observation.find(:first,:conditions => ["person_id = ? AND encounter_id = ? AND concept_id = ?",
            self.id,encounter.id,ConceptName.find_by_name('ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT').concept_id])).blank? 
      regimen_value_text = Concept.find(regimen_prescribed).short_name
      regimen_value_text = ConceptName.find_by_concept_id(regimen_prescribed).name if regimen_value_text.blank?
      obs = Observation.new(
        :concept_name => "ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT",
        :person_id => self.id,
        :encounter_id => encounter.id,
        :value_text => regimen_value_text,
        :value_coded => regimen_prescribed,
        :obs_datetime => encounter.encounter_datetime)
      obs.save
      return obs.value_text 
    end
  end

  def gender
    self.person.sex
  end

  def last_art_visit_before(date = Date.today)
    art_encounters = ['ART_INITIAL','HIV RECEPTION','VITALS','HIV STAGING','ART VISIT','ART ADHERENCE','TREATMENT','DISPENSING']
    art_encounter_type_ids = EncounterType.find(:all,:conditions => ["name IN (?)",art_encounters]).map{|e|e.encounter_type_id}
    Encounter.find(:first,
      :conditions => ["DATE(encounter_datetime) < ? AND patient_id = ? AND encounter_type IN (?)",date,
        self.id,art_encounter_type_ids],
      :order => 'encounter_datetime DESC').encounter_datetime.to_date rescue nil
  end
  
  def drug_given_before(date = Date.today)
    encounter_type = EncounterType.find_by_name('TREATMENT')
    Encounter.find(:first,
      :joins => 'INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
               INNER JOIN drug_order ON orders.order_id = orders.order_id', 
      :conditions => ["quantity IS NOT NULL AND encounter_type = ? AND 
               encounter.patient_id = ? AND DATE(encounter_datetime) < ?",
        encounter_type.id,self.id,date.to_date],:order => 'encounter_datetime DESC').orders rescue []
  end

  def prescribe_arv_this_visit(date = Date.today)
    encounter_type = EncounterType.find_by_name('ART VISIT')
    yes_concept = ConceptName.find_by_name('YES').concept_id
    refer_concept = ConceptName.find_by_name('PRESCRIBE ARVS THIS VISIT').concept_id
    refer_patient = Encounter.find(:first,
      :joins => 'INNER JOIN obs USING (encounter_id)', 
      :conditions => ["encounter_type = ? AND concept_id = ? AND person_id = ? AND value_coded = ? AND DATE(obs_datetime) = ?",
        encounter_type.id,refer_concept,self.id,yes_concept,date.to_date],:order => 'encounter_datetime DESC')
    return false if refer_patient.blank?
    return true
  end

  def number_of_days_to_add_to_next_appointment_date(date = Date.today)
    #because a dispension/pill count can have several drugs,we pick the drug with the lowest pill count
    #and we also make sure the drugs in the pill count/Adherence encounter are the same as the one in Dispension encounter
    
    concept_id = ConceptName.find_by_name('AMOUNT OF DRUG BROUGHT TO CLINIC').concept_id
    encounter_type = EncounterType.find_by_name('ART ADHERENCE')
    adherence = Observation.find(:all,
      :joins => 'INNER JOIN encounter USING(encounter_id)',
      :conditions =>["encounter_type = ? AND patient_id = ? AND concept_id = ? AND DATE(encounter_datetime)=?",
        encounter_type.id,self.id,concept_id,date.to_date],:order => 'encounter_datetime DESC')
    return 0 if adherence.blank?
    concept_id = ConceptName.find_by_name('AMOUNT DISPENSED').concept_id
    encounter_type = EncounterType.find_by_name('DISPENSING')
    drug_dispensed = Observation.find(:all,
      :joins => 'INNER JOIN encounter USING(encounter_id)',
      :conditions =>["encounter_type = ? AND patient_id = ? AND concept_id = ? AND DATE(encounter_datetime)=?",
        encounter_type.id,self.id,concept_id,date.to_date],:order => 'encounter_datetime DESC')

    #check if what was dispensed is what was counted as remaing pills
    return 0 unless (drug_dispensed.map{| d | d.value_drug } - adherence.map{|a|a.order.drug_order.drug_inventory_id}) == []
   
    #the folliwing block of code picks the drug with the lowest pill count
    count_drug_count = []
    (adherence).each do | adh |
      unless count_drug_count.blank?
        if adh.value_numeric < count_drug_count[1]
          count_drug_count = [adh.order.drug_order.drug_inventory_id,adh.value_numeric]
        end
      end
      count_drug_count = [adh.order.drug_order.drug_inventory_id,adh.value_numeric] if count_drug_count.blank?
    end

    #from the drug dispensed on that day,we pick the drug "plus it's daily dose" that match the drug with the lowest pill count    
    equivalent_daily_dose = 1
    (drug_dispensed).each do | dispensed_drug |
      drug_order = dispensed_drug.order.drug_order
      if count_drug_count[0] == drug_order.drug_inventory_id
        equivalent_daily_dose = drug_order.equivalent_daily_dose
      end
    end
    (count_drug_count[1] / equivalent_daily_dose).to_i
  end

  def age
    patient = Person.find(self.id)
    return patient.age
  end

  def residence
    patient = Person.find(self.id)
    return patient.address
  end

  def current_visit
    current_visit = self.visits.current.last
  end

  def previous_visits
    previous_visits = self.visits.all - self.visits.current
  end

  def self.active_range(patient_id, date = Date.today)
    patient = self.find(patient_id) rescue nil
    
    current_range = {}
    
    active_date = date
      
    pregnancies = {}; 
    
    # active_years = {}
    
    patient.encounters.active.find(:all, :order => ["encounter_datetime DESC"]).each{|e| 
      if e.name == "CURRENT PREGNANCY" && !pregnancies[e.encounter_datetime.strftime("%Y-%m-%d")]       
        pregnancies[e.encounter_datetime.strftime("%Y-%m-%d")] = {}        
        
        e.observations.each{|o| 
          concept = o.concept.name rescue nil
          if concept
            # if !active_years[e.encounter_datetime.beginning_of_quarter.strftime("%Y-%m-%d")]                            
            if o.concept.name.name.upcase == "DATE OF LAST MENSTRUAL PERIOD"         
              pregnancies[e.encounter_datetime.strftime("%Y-%m-%d")][o.concept.name.name.upcase] = o.answer_string          
              # active_years[e.encounter_datetime.beginning_of_quarter.strftime("%Y-%m-%d")] = true 
            end              
            # end
          end   
        } 
      end   
    }    
    
    # pregnancies = pregnancies.delete_if{|x, v| v == {}}
    
    pregnancies.each{|preg|
      if preg[1]["DATE OF LAST MENSTRUAL PERIOD"]
        preg[1]["START"] = preg[1]["DATE OF LAST MENSTRUAL PERIOD"].to_date
        preg[1]["END"] = preg[1]["DATE OF LAST MENSTRUAL PERIOD"].to_date + 7.day + 9.month        
      else
        preg[1]["START"] = preg[0].to_date
        preg[1]["END"] = preg[0].to_date + 7.day + 9.month
      end
      
      if active_date >= preg[1]["START"] && active_date <= preg[1]["END"]
        current_range["START"] = preg[1]["START"]
        current_range["END"] = preg[1]["END"]
      end
    }
    
    return [current_range, pregnancies]
  end
  
  def detailed_obstetric_history_label(date = Date.today)
    @patient = self rescue nil
    
    @obstetrics = {}
    search_set = ["YEAR OF BIRTH", "PLACE OF BIRTH", "PREGNANCY", "LABOUR DURATION", 
      "METHOD OF DELIVERY", "CONDITION AT BIRTH", "BIRTH WEIGHT", "ALIVE", 
      "AGE AT DEATH", "UNITS OF AGE OF CHILD", "PROCEDURE DONE"]
    current_level = 0
    
    @patient.encounters.active.all.each{|e| 
      e.observations.active.each{|obs|
        concept = obs.concept.name.name rescue nil
        if(!concept.nil?)
          if search_set.include?(concept.upcase)
            if obs.concept.name.name.upcase.eql?("YEAR OF BIRTH")
              current_level += 1
            
              @obstetrics[current_level] = {}
            end
          
            if @obstetrics[current_level]
              @obstetrics[current_level][concept.upcase] = obs.answer_string rescue nil
              
              if concept.upcase == "YEAR OF BIRTH" && obs.answer_string.to_i == 0
                @obstetrics[current_level][concept.upcase] = "Unknown"
              end
            end
                        
          end
        end
      }      
    }
    
    # raise @obstetrics.to_yaml
    
    @pregnancies = Patient.active_range(@patient.id)
    
    @range = []
    
    @pregnancies = @pregnancies[1]
    
    @pregnancies.each{|preg|
      @range << preg[0].to_date
    }
    
    @range = @range.sort    
    
    @range.each{|y|
      current_level += 1
      @obstetrics[current_level] = {}
      @obstetrics[current_level]["YEAR OF BIRTH"] = y.year
      @obstetrics[current_level]["PLACE OF BIRTH"] = "(Here)"
    }
    
    label = ZebraPrinter::StandardLabel.new
    label2 = ZebraPrinter::StandardLabel.new
    label2set = false
    label3 = ZebraPrinter::StandardLabel.new
    label3set = false

    label.draw_text("Detailed Obstetric History",28,29,0,1,1,2,false)
    label.draw_text("Pr.",25,65,0,2,1,1,false)
    label.draw_text("No.",25,85,0,2,1,1,false)
    label.draw_text("Year",59,65,0,2,1,1,false)
    label.draw_text("Place",110,65,0,2,1,1,false)
    label.draw_text("Gest.",225,65,0,2,1,1,false)
    label.draw_text("(wks)",225,85,0,2,1,1,false)
    label.draw_text("Labour",305,65,0,2,1,1,false)
    label.draw_text("durat.",305,85,0,2,1,1,false)
    label.draw_text("(hrs)",310,105,0,2,1,1,false)
    label.draw_text("Delivery",405,65,0,2,1,1,false)
    label.draw_text("Method",410,85,0,2,1,1,false)
    label.draw_text("Conditi.",518,65,0,2,1,1,false)
    label.draw_text("at birth",518,85,0,2,1,1,false)
    label.draw_text("Birt.",625,65,0,2,1,1,false)
    label.draw_text("weigh.",620,85,0,2,1,1,false)
    label.draw_text("(kg)",625,105,0,2,1,1,false)
    label.draw_text("Aliv.",690,65,0,2,1,1,false)
    label.draw_text("now?",690,85,0,2,1,1,false)
    label.draw_text("Age at",745,65,0,2,1,1,false)
    label.draw_text("death*",745,85,0,2,1,1,false)
    
    label.draw_line(20,60,800,2,0)
    label.draw_line(20,60,2,245,0)
    label.draw_line(20,305,800,2,0)
    label.draw_line(805,60,2,245,0)
    label.draw_line(20,125,800,2,0)
    
    label.draw_line(56,60,2,245,0)
    label.draw_line(105,60,2,245,0)
    label.draw_line(220,60,2,245,0)
    label.draw_line(295,60,2,245,0)
    label.draw_line(380,60,2,245,0)
    label.draw_line(510,60,2,245,0)
    label.draw_line(615,60,2,245,0)
    label.draw_line(683,60,2,245,0)
    label.draw_line(740,60,2,245,0)
    
    (1..(@obstetrics.length + 1)).each do |pos|
      
      @place = (@obstetrics[pos] ? (@obstetrics[pos]["PLACE OF BIRTH"] ? 
            @obstetrics[pos]["PLACE OF BIRTH"] : "") : "").gsub(/Centre/i, 
        "C.").gsub(/Health/i, "H.").gsub(/Center/i, "C.")
          
      @gest = (@obstetrics[pos] ? (@obstetrics[pos]["PREGNANCY"] ? 
            @obstetrics[pos]["PREGNANCY"] : "") : "")
          
      @gest = (@gest.length > 5 ? truncate(@gest, 5) : @gest)
              
      @delmode = (@obstetrics[pos] ? (@obstetrics[pos]["METHOD OF DELIVERY"] ? 
            @obstetrics[pos]["METHOD OF DELIVERY"].titleize : (@obstetrics[pos]["PROCEDURE DONE"] ? 
              @obstetrics[pos]["PROCEDURE DONE"] : "")) : "").gsub(/Spontaneous\sVaginal\sDelivery/i, 
        "S.V.D.").gsub(/Caesarean\sSection/i, "C-Section").gsub(/Vacuum\sExtraction\sDelivery/i, 
        "Vac. Extr.").gsub("(MVA)", "").gsub(/Manual\sVacuum\sAspiration/i, 
        "M.V.A.").gsub(/Evacuation/i, "Evac")
             
      @labor = (@obstetrics[pos] ? (@obstetrics[pos]["LABOUR DURATION"] ? 
            @obstetrics[pos]["LABOUR DURATION"] : "") : "")
             
      @labor = (@labor.length > 5 ? truncate(@labor,5) : @labor)
        
      @cond = (@obstetrics[pos] ? (@obstetrics[pos]["CONDITION AT BIRTH"] ? 
            @obstetrics[pos]["CONDITION AT BIRTH"] : "") : "").titleize
        
      if pos <= 3
        
        label.draw_text(pos,28,(85 + (60 * pos)),0,2,1,1,false)
        
        label.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["YEAR OF BIRTH"] ? 
                (@obstetrics[pos]["YEAR OF BIRTH"].to_i > 0 ? @obstetrics[pos]["YEAR OF BIRTH"].to_i : 
                  "????") : "") : ""),58,(70 + (60 * pos)),0,2,1,1,false)
                
        if @place.length < 9
          label.draw_text(@place,111,(70 + (60 * pos)),0,2,1,1,false)
        else
          @place = paragraphate(@place)
        
          (0..(@place.length)).each{|p|
            label.draw_text(@place[p],111,(70 + (60 * pos) + (18 * p)),0,2,1,1,false)
          }
        end
          
        label.draw_text(@gest,225,(70 + (60 * pos)),0,2,1,1,false)
            
        label.draw_text(@labor,300,(70 + (60 * pos)),0,2,1,1,false)
             
        if @delmode.length < 11
          label.draw_text(@delmode,385,(70 + (60 * pos)),0,2,1,1,false)
        else
          @delmode = paragraphate(@delmode)
        
          (0..(@delmode.length)).each{|p|
            label.draw_text(@delmode[p],385,(70 + (60 * pos) + (13 * p)),0,2,1,1,false)
          }
        end
        
        if @cond.length < 6
          label.draw_text(@cond,515,(70 + (60 * pos)),0,2,1,1,false)
        else
          @cond = paragraphate(@cond, 6)
        
          (0..(@cond.length)).each{|p|
            label.draw_text(@cond[p],515,(70 + (60 * pos) + (18 * p)),0,2,1,1,false)
          }
        end
        
        label.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["BIRTH WEIGHT"] ? 
                @obstetrics[pos]["BIRTH WEIGHT"] : "") : ""),620,(70 + (60 * pos)),0,2,1,1,false)
        
        label.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["ALIVE"] ? 
                @obstetrics[pos]["ALIVE"] : "") : ""),687,(70 + (60 * pos)),0,2,1,1,false)
        
        label.draw_text(truncate((@obstetrics[pos] ? (@obstetrics[pos]["AGE AT DEATH"] ? 
                  (@obstetrics[pos]["AGE AT DEATH"].to_s.match(/\.[1-9]/) ? @obstetrics[pos]["AGE AT DEATH"] : 
                    @obstetrics[pos]["AGE AT DEATH"].to_i) : "") : "").to_s + 
              (@obstetrics[pos] ? (@obstetrics[pos]["UNITS OF AGE OF CHILD"] ? 
                  @obstetrics[pos]["UNITS OF AGE OF CHILD"] : "") : ""), 5),745,(70 + (60 * pos)),0,2,1,1,false)
        
        label.draw_line(20,((135 + (45 * pos)) <= 305 ? (125 + (60 * pos)) : 305),800,2,0)
        
      elsif pos >= 4 && pos <= 8
        if pos == 4
          label2.draw_line(20,30,800,2,0)
          label2.draw_line(20,30,2,275,0)
          label2.draw_line(20,305,800,2,0)
          label2.draw_line(805,30,2,275,0)
          
          label2.draw_line(55,30,2,275,0)
          label2.draw_line(105,30,2,275,0)
          label2.draw_line(220,30,2,275,0)
          label2.draw_line(295,30,2,275,0)
          label2.draw_line(380,30,2,275,0)
          label2.draw_line(510,30,2,275,0)
          label2.draw_line(615,30,2,275,0)
          label2.draw_line(683,30,2,275,0)
          label2.draw_line(740,30,2,275,0)
        end
        label2.draw_text(pos,28,((55 * (pos - 3))),0,2,1,1,false)
        
        label2.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["YEAR OF BIRTH"] ? 
                (@obstetrics[pos]["YEAR OF BIRTH"].to_i > 0 ? @obstetrics[pos]["YEAR OF BIRTH"].to_i : 
                  "????") : "") : ""),58,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        if @place.length < 8
          label2.draw_text(@place,111,((55 * (pos - 3)) - 13),0,2,1,1,false)
        else
          @place = paragraphate(@place)
        
          (0..(@place.length)).each{|p|
            label2.draw_text(@place[p],111,(55 * (pos - 3) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        label2.draw_text(@gest,225,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        label2.draw_text(@labor,300,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        if @delmode.length < 11
          label2.draw_text(@delmode,385,(55 * (pos - 3)),0,2,1,1,false)
        else
          @delmode = paragraphate(@delmode)
        
          (0..(@delmode.length)).each{|p|
            label2.draw_text(@delmode[p],385,(55 * (pos - 3) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        if @cond.length < 6
          label2.draw_text(@cond,515,((55 * (pos - 3)) - 13),0,2,1,1,false)
        else
          @cond = paragraphate(@cond, 6)
        
          (0..(@cond.length)).each{|p|
            label2.draw_text(@cond[p],515,(55 * (pos - 3) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        label2.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["BIRTH WEIGHT"] ? 
                @obstetrics[pos]["BIRTH WEIGHT"] : "") : ""),620,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        label2.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["ALIVE"] ? 
                @obstetrics[pos]["ALIVE"] : "") : ""),687,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        label2.draw_text(truncate((@obstetrics[pos] ? (@obstetrics[pos]["AGE AT DEATH"] ? 
                  (@obstetrics[pos]["AGE AT DEATH"].to_s.match(/\.[1-9]/) ? @obstetrics[pos]["AGE AT DEATH"] : 
                    @obstetrics[pos]["AGE AT DEATH"].to_i) : "") : "").to_s + 
              (@obstetrics[pos] ? (@obstetrics[pos]["UNITS OF AGE OF CHILD"] ? 
                  @obstetrics[pos]["UNITS OF AGE OF CHILD"] : "") : ""),5),745,((55 * (pos - 3)) - 13),0,2,1,1,false)
        
        label2.draw_line(20,(((55 * (pos - 3)) + 35) <= 305 ? ((55 * (pos - 3)) + 35) : 305),800,2,0)
        label2set = true
      else
        if pos == 9
          label3.draw_line(20,30,800,2,0)
          label3.draw_line(20,30,2,275,0)
          label3.draw_line(20,305,800,2,0)
          label3.draw_line(805,30,2,275,0)
          
          label3.draw_line(55,30,2,275,0)
          label3.draw_line(105,30,2,275,0)
          label3.draw_line(220,30,2,275,0)
          label3.draw_line(295,30,2,275,0)
          label3.draw_line(380,30,2,275,0)
          label3.draw_line(510,30,2,275,0)
          label3.draw_line(615,30,2,275,0)
          label3.draw_line(683,30,2,275,0)
          label3.draw_line(740,30,2,275,0)
        end
        label3.draw_text(pos,28,((55 * (pos - 8))),0,2,1,1,false)
        
        label3.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["YEAR OF BIRTH"] ? 
                (@obstetrics[pos]["YEAR OF BIRTH"].to_i > 0 ? @obstetrics[pos]["YEAR OF BIRTH"].to_i : 
                  "????") : "") : ""),58,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        if @place.length < 8
          label3.draw_text(@place,111,((55 * (pos - 8)) - 13),0,2,1,1,false)
        else
          @place = paragraphate(@place)
        
          (0..(@place.length)).each{|p|
            label3.draw_text(@place[p],111,(55 * (pos - 8) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        label3.draw_text(@gest,225,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        label3.draw_text(@labor,300,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        if @delmode.length < 11
          label3.draw_text(@delmode,385,(55 * (pos - 8)),0,2,1,1,false)
        else
          @delmode = paragraphate(@delmode)
        
          (0..(@delmode.length)).each{|p|
            label3.draw_text(@delmode[p],385,(55 * (pos - 8) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        if @cond.length < 6
          label3.draw_text(@cond,515,((55 * (pos - 8)) - 13),0,2,1,1,false)
        else
          @cond = paragraphate(@cond, 6)
        
          (0..(@cond.length)).each{|p|
            label3.draw_text(@cond[p],515,(55 * (pos - 8) + (18 * p))-17,0,2,1,1,false)
          }
        end
        
        label3.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["BIRTH WEIGHT"] ? 
                @obstetrics[pos]["BIRTH WEIGHT"] : "") : ""),620,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        label3.draw_text((@obstetrics[pos] ? (@obstetrics[pos]["ALIVE"] ? 
                @obstetrics[pos]["ALIVE"] : "") : ""),687,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        label3.draw_text(truncate((@obstetrics[pos] ? (@obstetrics[pos]["AGE AT DEATH"] ? 
                  (@obstetrics[pos]["AGE AT DEATH"].to_s.match(/\.[1-9]/) ? @obstetrics[pos]["AGE AT DEATH"] : 
                    @obstetrics[pos]["AGE AT DEATH"].to_i) : "") : "").to_s + 
              (@obstetrics[pos] ? (@obstetrics[pos]["UNITS OF AGE OF CHILD"] ? 
                  @obstetrics[pos]["UNITS OF AGE OF CHILD"] : "") : ""),5),745,((55 * (pos - 8)) - 13),0,2,1,1,false)
        
        label3.draw_line(20,(((55 * (pos - 8)) + 35) <= 305 ? ((55 * (pos - 8)) + 35) : 305),800,2,0)
        label3set = true
      end
      
    end
    
    if label3set
      label.print(1) + label2.print(1) + label3.print(1)
    elsif label2set
      label.print(1) + label2.print(1)
    else
      label.print(1)
    end    
  end
  
  def obstetric_medical_history_label(date = Date.today)
    @patient = self rescue nil
     
    @pregnancies = Patient.active_range(@patient.id)
    
    @range = []
    
    @pregnancies = @pregnancies[1]
    
    @pregnancies.each{|preg|
      @range << preg[0].to_date
    }
    
    @deliveries = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('PARITY').concept_id]).answer_string.to_i rescue nil

    @deliveries = @deliveries + (@range.length > 0 ? @range.length - 1 : @range.length) if !@deliveries.nil?
    
    @gravida = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('GRAVIDA').concept_id]).answer_string.to_i rescue nil

    @multipreg = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all, :conditions => ["encounter_type = ?", 
            EncounterType.find_by_name("OBSTETRIC HISTORY").id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('MULTIPLE GESTATION').concept_id]).answer_string rescue nil

    @abortions = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('NUMBER OF ABORTIONS').concept_id]).answer_string.to_i rescue nil

    @stillbirths = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('STILL BIRTH').concept_id]).answer_string rescue nil

    #Observation.find(:all, :conditions => ["person_id = ? AND encounter_id IN (?) AND value_coded = ?", 40, Encounter.active.find(:all, :conditions => ["patient_id = ?", 40]).collect{|e| e.encounter_id}, ConceptName.find_by_name('Caesarean section').concept_id])
    
    @csections = Observation.find(:all,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND value_coded = ?", @patient.id,
        Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Caesarean section').concept_id]).length rescue nil

    @vacuum = Observation.find(:all,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND value_coded = ?", @patient.id,
        Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Vacuum extraction delivery').concept_id]).length rescue nil

    @symphosio = Observation.find(:last, 
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('SYMPHYSIOTOMY').concept_id]).answer_string rescue nil

    @haemorrhage = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('HEMORRHAGE').concept_id]).answer_string rescue nil

    @preeclampsia = Observation.find(:last,
      :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?", @patient.id,
        Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('PRE-ECLAMPSIA').concept_id]).answer_string rescue nil

    @asthma = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('ASTHMA').concept_id]).answer_string.upcase rescue nil

    @hyper = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('HYPERTENSION').concept_id]).answer_string.upcase rescue nil

    @diabetes = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('DIABETES').concept_id]).answer_string.upcase rescue nil

    @epilepsy = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('EPILEPSY').concept_id]).answer_string.upcase rescue nil

    @renal = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('RENAL DISEASE').concept_id]).answer_string.upcase rescue nil

    @fistula = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('FISTULA REPAIR').concept_id]).answer_string.upcase rescue nil

    @deform = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('SPINE OR LEG DEFORM').concept_id]).answer_string.upcase rescue nil

    @surgicals = Observation.find(:all, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["patient_id = ? AND encounter_type = ?", 
            @patient.id, EncounterType.find_by_name("SURGICAL HISTORY").id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('PROCEDURE DONE').concept_id]).collect{|o| 
      "#{o.answer_string} (#{o.obs_datetime.strftime('%d-%b-%Y')})"} rescue []

    @age = @patient.age rescue 0

    label = ZebraPrinter::StandardLabel.new

    label.draw_text("Obstetric History",28,29,0,1,1,2,false)
    label.draw_text("Medical History",400,29,0,1,1,2,false)
    label.draw_text("Refer",750,29,0,1,1,2,true)
    label.draw_line(25,60,172,1,0)
    label.draw_line(400,60,152,1,0)
    label.draw_text("Gravida",28,80,0,2,1,1,false)
    label.draw_text("Asthma",400,80,0,2,1,1,false)
    label.draw_text("Deliveries",28,110,0,2,1,1,false)
    label.draw_text("Hypertension",400,110,0,2,1,1,false)
    label.draw_text("Abortions",28,140,0,2,1,1,false)
    label.draw_text("Diabetes",400,140,0,2,1,1,false)
    label.draw_text("Still Births",28,170,0,2,1,1,false)
    label.draw_text("Epilepsy",400,170,0,2,1,1,false)
    label.draw_text("Vacuum Extraction",28,200,0,2,1,1,false)
    label.draw_text("Renal Disease",400,200,0,2,1,1,false)
    label.draw_text("Symphisiotomy",28,230,0,2,1,1,false)
    label.draw_text("Fistula Repair",400,230,0,2,1,1,false)
    label.draw_text("Haemorrhage",28,260,0,2,1,1,false)
    label.draw_text("Leg/Spine Deformation",400,260,0,2,1,1,false)
    label.draw_text("Pre-Eclampsia",28,290,0,2,1,1,false)
    label.draw_text("Age",400,290,0,2,1,1,false)
    label.draw_line(250,70,130,1,0)
    label.draw_line(250,70,1,236,0)
    label.draw_line(250,306,130,1,0)
    label.draw_line(380,70,1,236,0)
    label.draw_line(250,100,130,1,0)
    label.draw_line(250,130,130,1,0)
    label.draw_line(250,160,130,1,0)
    label.draw_line(250,190,130,1,0)
    label.draw_line(250,220,130,1,0)
    label.draw_line(250,250,130,1,0)
    label.draw_line(250,280,130,1,0)
    label.draw_line(659,70,130,1,0)
    label.draw_line(659,70,1,236,0)
    label.draw_line(659,306,130,1,0)
    label.draw_line(790,70,1,236,0)
    label.draw_line(659,100,130,1,0)
    label.draw_line(659,130,130,1,0)
    label.draw_line(659,160,130,1,0)
    label.draw_line(659,190,130,1,0)
    label.draw_line(659,220,130,1,0)
    label.draw_line(659,250,130,1,0)
    label.draw_line(659,280,130,1,0)
    label.draw_text("#{@gravida}",280,80,0,2,1,1,false)
    label.draw_text("#{@deliveries}",280,110,0,2,1,1,(@deliveries > 4 ? true : false))
    label.draw_text("#{@abortions}",280,140,0,2,1,1,(@abortions > 1 ? true : false))
    label.draw_text("#{(!@stillbirths.nil? ? (@stillbirths == "NO" ? "NO" : "YES") : "")}",280,170,0,2,1,1,
      (!@stillbirths.nil? ? (@stillbirths == "NO" ? false : true) : false))
    label.draw_text("#{(!@vacuum.nil? ? (@vacuum > 0 ? "YES" : "NO") : "")}",280,200,0,2,1,1,
      (!@vacuum.nil? ? (@vacuum > 0 ? true : false) : false))
    label.draw_text("#{(!@symphosio.nil? ? (@symphosio == "NO" ? "NO" : "YES") : "")}",280,230,0,2,1,1,
      (!@symphosio.nil? ? (@symphosio == "NO" ? false : true) : false))
    label.draw_text("#{@haemorrhage}",280,260,0,2,1,1,(@haemorrhage == "PPH" ? true : false))
    label.draw_text("#{(!@preeclampsia.nil? ? (@preeclampsia == "NO" ? "NO" : "YES") : "")}",280,285,0,2,1,1,
      (!@preeclampsia.nil? ? (@preeclampsia == "NO" ? false : true) : false))
    
    label.draw_text("#{(!@asthma.nil? ? (@asthma == "NO" ? "NO" : "YES") : "")}",690,80,0,2,1,1,
      (!@asthma.nil? ? (@asthma == "NO" ? false : true) : false))
    label.draw_text("#{(!@hyper.nil? ? (@hyper == "NO" ? "NO" : "YES") : "")}",690,110,0,2,1,1,
      (!@hyper.nil? ? (@hyper == "NO" ? false : true) : false))
    label.draw_text("#{(!@diabetes.nil? ? (@diabetes == "NO" ? "NO" : "YES") : "")}",690,140,0,2,1,1,
      (!@diabetes.nil? ? (@diabetes == "NO" ? false : true) : false))
    label.draw_text("#{(!@epilepsy.nil? ? (@epilepsy == "NO" ? "NO" : "YES") : "")}",690,170,0,2,1,1,
      (!@epilepsy.nil? ? (@epilepsy == "NO" ? false : true) : false))
    label.draw_text("#{(!@renal.nil? ? (@renal == "NO" ? "NO" : "YES") : "")}",690,200,0,2,1,1,
      (!@renal.nil? ? (@renal == "NO" ? false : true) : false))
    label.draw_text("#{(!@fistula.nil? ? (@fistula == "NO" ? "NO" : "YES") : "")}",690,230,0,2,1,1,
      (!@fistula.nil? ? (@fistula == "NO" ? false : true) : false))
    label.draw_text("#{(!@deform.nil? ? (@deform == "NO" ? "NO" : "YES") : "")}",690,260,0,2,1,1,
      (!@deform.nil? ? (@deform == "NO" ? false : true) : false))
    label.draw_text("#{@age}",690,285,0,2,1,1,
      (((@age > 0 && @age < 16) || (@age > 40)) ? true : false))

    label.print(1)
  end
  
  def examination_label(target_date = Date.today)
    @patient = self rescue nil

    syphil = {}
    @patient.encounters.find(:all, :conditions => ["encounter_type IN (?)", 
        EncounterType.find_by_name("LAB RESULTS").id]).each{|e| 
      e.observations.active.each{|o| 
        syphil[o.concept.name.name.upcase] = o.answer_string.upcase
      }      
    }
    
    @syphilis = syphil["SYPHILIS TEST RESULT"].titleize rescue nil

    @syphilis_date = syphil["SYPHILIS TEST RESULT DATE"].to_date.strftime("%Y/%m/%d") rescue nil

    @hiv_test = syphil["HIV STATUS"].titleize rescue nil

    @hiv_test_date = syphil["HIV TEST DATE"].to_date.strftime("%Y/%m/%d") rescue nil

    hb = {}; pos = 1; 
    
    @patient.encounters.active.find(:all, 
      :order => "encounter_datetime DESC", :conditions => ["encounter_type = ?", 
        EncounterType.find_by_name("LAB RESULTS").id]).each{|e| 
      e.observations.active.each{|o| hb[o.concept.name.name.upcase + " " + 
            pos.to_s] = o.answer_string.upcase; pos += 1 if o.concept.name.name.upcase == "HB TEST RESULT DATE";
      }      
    }
    
    @hb1 = hb["HB TEST RESULT 1"] rescue nil

    @hb1_date = hb["HB TEST RESULT DATE 1"].to_date.strftime("%Y/%m/%d") rescue nil

    @hb2 = hb["HB TEST RESULT 2"] rescue nil

    @hb2_date = hb["HB TEST RESULT DATE 2"].to_date.strftime("%Y/%m/%d") rescue nil

    @cd4 = syphil['CD4 COUNT'] rescue nil

    @cd4_date = syphil['CD4 COUNT DATETIME'].to_date.strftime("%Y/%m/%d") rescue nil

    @height = @patient.current_height.to_i

    @multiple = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all, :conditions => ["encounter_type = ?", 
            EncounterType.find_by_name("CURRENT PREGNANCY").id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Multiple Gestation').concept_id]).answer_string rescue nil

    @who = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.active.find(:all).collect{|e| e.encounter_id},
        ConceptName.find_by_name('WHO STAGE').concept_id]).answer_string.to_i rescue nil

    label = ZebraPrinter::StandardLabel.new   
    
    label.draw_text("Examination",28,29,0,1,1,2,false)
    label.draw_line(25,55,115,1,0)
    label.draw_line(25,190,115,1,0)
    label.draw_text("Height",28,76,0,2,1,1,false)
    label.draw_text("Multiple Pregnancy",28,106,0,2,1,1,false)
    label.draw_text("WHO Clinical Stage",28,136,0,2,1,1,false)
    label.draw_text("Lab Results",28,161,0,1,1,2,false)
    label.draw_text("Date",190,170,0,2,1,1,false)
    label.draw_text("Result",325,170,0,2,1,1,false)
    label.draw_text("HIV",28,196,0,2,1,1,false)
    label.draw_text("Syphilis",28,226,0,2,1,1,false)
    label.draw_text("Hb1",28,256,0,2,1,1,false)
    label.draw_text("Hb2",28,286,0,2,1,1,false)
    label.draw_line(260,70,170,1,0)
    label.draw_line(260,70,1,90,0)
    label.draw_line(180,306,250,1,0)
    label.draw_line(430,70,1,90,0)
    
    label.draw_line(180,190,1,115,0)
    label.draw_line(320,190,1,115,0)
    label.draw_line(430,190,1,115,0)
    
    label.draw_line(260,100,170,1,0)    
    label.draw_line(260,130,170,1,0)
    label.draw_line(260,160,170,1,0)
    
    label.draw_line(180,190,250,1,0)
    label.draw_line(180,220,250,1,0)
    label.draw_line(180,250,250,1,0)
    label.draw_line(180,280,250,1,0)
    
    label.draw_text(@height,270,76,0,2,1,1,false)
    label.draw_text(@multiple,270,106,0,2,1,1,false)
    label.draw_text(@who,270,136,0,2,1,1,false)
        
    label.draw_text(@hiv_test_date,190,196,0,2,1,1,false)
    label.draw_text(@syphilis_date,190,226,0,2,1,1,false)
    label.draw_text(@hb1_date,190,256,0,2,1,1,false)
    label.draw_text(@hb2_date,190,286,0,2,1,1,false)
        
    label.draw_text(@hiv_test,325,196,0,2,1,1,false)
    label.draw_text(@syphilis,325,226,0,2,1,1,false)
    label.draw_text(@hb1,325,256,0,2,1,1,false)
    label.draw_text(@hb2,325,286,0,2,1,1,false)
    
    label.print(1)
  end
  
  def visit_summary_label(target_date = Date.today)
    @patient = self rescue nil
    
    @current_range = Patient.active_range(@patient.id, target_date.to_date)

    # raise @current_range.to_yaml
    
    encounters = {}

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|    
      encounters[e.encounter_datetime.strftime("%d/%b/%Y")] = {"USER" => User.find(e.creator).name}      
    }

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e| 
      encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase] = ({} rescue "") if !e.type.nil?
    }

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e| 
      e.observations.each{|o| 
        if o.to_a[0]
          if o.to_a[0].upcase == "DIAGNOSIS" && encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase]
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] += "; " + o.to_a[1]
          else
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] = (o.to_a[1] rescue "") if !e.type.nil?
            if o.to_a[0].upcase == "PLANNED DELIVERY PLACE"
              @current_range[0]["PLANNED DELIVERY PLACE"] = o.to_a[1]
            elsif o.to_a[0].upcase == "MOSQUITO NET"
              @current_range[0]["MOSQUITO NET"] = o.to_a[1]
            end
          end
        end
      }
    }

    @drugs = {}; 
    @other_drugs = {}; 
    main_drugs = ["TTV", "SP", "Fefol", "NVP", "Albendazole", "TDF/3TC/EFV"]
    
    @patient.encounters.active.find(:all, :order => "encounter_datetime DESC", 
      :conditions => ["encounter_type = ? AND encounter_datetime >= ? AND encounter_datetime <= ?", 
        EncounterType.find_by_name("TREATMENT").id, @current_range[0]["START"], @current_range[0]["END"]]).each{|e| 
      @drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@drugs[e.encounter_datetime.strftime("%d/%b/%Y")]; 
      @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")]; 
      e.orders.each{|o| 
        if main_drugs.include?(o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")])          
          if o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")] == "NVP"
            if o.drug_order.drug.name.upcase.include?("ML")
              @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
            else
              @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
            end
          else            
            @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
          end          
        else
          @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
        end
      }      
    }
    
    label = ZebraPrinter::StandardLabel.new

    label.draw_line(20,25,800,2,0)
    label.draw_line(20,25,2,280,0)
    label.draw_line(20,305,800,2,0)
    label.draw_line(805,25,2,280,0)
    label.draw_text("Visit Summary",28,33,0,1,1,2,false)
    label.draw_text("Last Menstrual Period: #{@current_range[0]["START"].to_date.strftime("%d/%b/%Y") rescue ""}",28,76,0,2,1,1,false)
    label.draw_text("Expected Date of Delivery: #{@current_range[0]["END"].to_date.strftime("%d/%b/%Y") rescue ""}",28,99,0,2,1,1,false)
    label.draw_line(28,60,132,1,0)
    label.draw_line(20,130,800,2,0)
    label.draw_line(20,190,800,2,0)
    label.draw_text("Gest.",29,140,0,2,1,1,false)
    label.draw_text("Fundal",99,140,0,2,1,1,false)
    label.draw_text("Pos./",178,140,0,2,1,1,false)
    label.draw_text("Fetal",259,140,0,2,1,1,false)
    label.draw_text("Weight",339,140,0,2,1,1,false)
    label.draw_text("(kg)",339,158,0,2,1,1,false)
    label.draw_text("BP",435,140,0,2,1,1,false)
    label.draw_text("Urine",499,138,0,2,1,1,false)
    label.draw_text("Prote-",499,156,0,2,1,1,false)
    label.draw_text("in",505,174,0,2,1,1,false)
    label.draw_text("SP",595,140,0,2,1,1,false)
    label.draw_text("FeFo",664,140,0,2,1,1,false)
    label.draw_text("Albe.",740,140,0,2,1,1,false)
    label.draw_text("Age",35,158,0,2,1,1,false)
    label.draw_text("Height",99,158,0,2,1,1,false)
    label.draw_text("Pres.",178,158,0,2,1,1,false)
    label.draw_text("Heart",259,158,0,2,1,1,false)
    label.draw_line(90,130,2,175,0)
    label.draw_line(170,130,2,175,0)
    label.draw_line(250,130,2,175,0)
    label.draw_line(330,130,2,175,0)
    label.draw_line(410,130,2,175,0)
    label.draw_line(490,130,2,175,0)
    label.draw_line(570,130,2,175,0)
    label.draw_line(650,130,2,175,0)
    label.draw_line(730,130,2,175,0)
    
    @i = 0

    encounters.sort.each do |encounter|
      @i = @i + 1
      
      if encounter[0] == target_date.to_date.strftime("%d/%b/%Y")
        visit = encounters[encounter[0]]["ANC VISIT TYPE"]["REASON FOR VISIT"].to_i
        
        label.draw_text("Visit No: #{visit}",250,33,0,1,1,2,false)
        label.draw_text("Visit Date: #{encounter[0]}",450,33,0,1,1,2,false)
        
        gest = (((encounter[0].to_date - @current_range[0]["START"].to_date).to_i / 7) <= 0 ? "?" : 
            (((encounter[0].to_date - @current_range[0]["START"].to_date).to_i / 7) - 1).to_s + "wks") rescue ""
            
        label.draw_text(gest,29,200,0,2,1,1,false)
        
        fund = (encounters[encounter[0]]["OBSERVATIONS"]["FUNDUS"].to_i <= 0 ? "?" : 
            encounters[encounter[0]]["OBSERVATIONS"]["FUNDUS"].to_i.to_s + "(wks)") rescue ""
            
        label.draw_text(fund,99,200,0,2,1,1,false)
        
        posi = encounters[encounter[0]]["OBSERVATIONS"]["POSITION"] rescue ""
        pres = encounters[encounter[0]]["OBSERVATIONS"]["PRESENTATION"] rescue ""
        
        posipres = paragraphate(posi.to_s + pres.to_s,5, 5)
        
        (0..(posipres.length)).each{|u|
          label.draw_text(posipres[u],178,(200 + (13 * u)),0,2,1,1,false)
        }
        
        fet = (encounters[encounter[0]]["OBSERVATIONS"]["FETAL HEART BEAT"].humanize == "Unknown" ? "?" :
            encounters[encounter[0]]["OBSERVATIONS"]["FETAL HEART BEAT"].humanize) rescue ""
        
        fet = paragraphate(fet, 5, 5)
        
        (0..(fet.length)).each{|f|
          label.draw_text(fet[f],259,(200 + (13 * f)),0,2,1,1,false)
        }
        
        wei = (encounters[encounter[0]]["VITALS"]["WEIGHT (KG)"].to_i <= 0 ? "?" : 
            ((encounters[encounter[0]]["VITALS"]["WEIGHT (KG)"].to_s.match(/\.[1-9]/) ? 
                encounters[encounter[0]]["VITALS"]["WEIGHT (KG)"] : 
                encounters[encounter[0]]["VITALS"]["WEIGHT (KG)"].to_i))) rescue ""
        
        label.draw_text(wei,339,200,0,2,1,1,false)
        
        sbp = (encounters[encounter[0]]["VITALS"]["SYSTOLIC BLOOD PRESSURE"].to_i <= 0 ? "?" : 
            encounters[encounter[0]]["VITALS"]["SYSTOLIC BLOOD PRESSURE"].to_i) rescue "?"
            
        dbp = (encounters[encounter[0]]["VITALS"]["DIASTOLIC BLOOD PRESSURE"].to_i <= 0 ? "?" : 
            encounters[encounter[0]]["VITALS"]["DIASTOLIC BLOOD PRESSURE"].to_i) rescue "?"
        
        bp = paragraphate(sbp.to_s + "/" + dbp.to_s, 4, 3)
        
        (0..(bp.length)).each{|u|
          label.draw_text(bp[u],420,(200 + (18 * u)),0,2,1,1,false)
        }
        
        uri = encounters[encounter[0]]["LAB RESULTS"]["URINE PROTEIN"] rescue ""
        
        uri = paragraphate(uri, 5, 5)
        
        (0..(uri.length)).each{|u|
          label.draw_text(uri[u],498,(200 + (18 * u)),0,2,1,1,false)
        }
        
        sp = (@drugs[encounter[0]]["SP"].to_i > 0 ? @drugs[encounter[0]]["SP"].to_i : "") rescue ""
        
        label.draw_text(sp,595,200,0,2,1,1,false)
        
        fefo = (@drugs[encounter[0]]["Fefol"].to_i > 0 ? @drugs[encounter[0]]["Fefol"].to_i : "") rescue ""
        
        label.draw_text(fefo,664,200,0,2,1,1,false)
        
        albe = (@drugs[encounter[0]]["Albendazole"].to_i > 0 ? @drugs[encounter[0]]["Albendazole"].to_i : "") rescue ""
        
        label.draw_text(albe,740,200,0,2,1,1,false)
      end 
      
    end
    
    @encounters = encounters
    
    label.print(1)
  end
  
  def visit_summary2_label(target_date = Date.today)
    @patient = self rescue nil
    
    @current_range = Patient.active_range(@patient.id, target_date.to_date)

    # raise @current_range.to_yaml
    
    encounters = {}

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e|    
      encounters[e.encounter_datetime.strftime("%d/%b/%Y")] = {"USER" => User.find(e.creator).name}      
    }

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e| 
      encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase] = ({} rescue "") if !e.type.nil?
    }

    @patient.encounters.active.find(:all, :conditions => ["encounter_datetime >= ? AND encounter_datetime <= ?", 
        @current_range[0]["START"], @current_range[0]["END"]]).collect{|e| 
      e.observations.each{|o| 
        if o.to_a[0]
          if o.to_a[0].upcase == "DIAGNOSIS" && encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase]
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] += "; " + o.to_a[1]
          else
            encounters[e.encounter_datetime.strftime("%d/%b/%Y")][e.type.name.upcase][o.to_a[0].upcase] = (o.to_a[1] rescue "") if !e.type.nil?
            if o.to_a[0].upcase == "PLANNED DELIVERY PLACE"
              @current_range[0]["PLANNED DELIVERY PLACE"] = o.to_a[1]
            elsif o.to_a[0].upcase == "MOSQUITO NET"
              @current_range[0]["MOSQUITO NET"] = o.to_a[1]
            end
          end
        end
      }
    }

    @drugs = {}; 
    @other_drugs = {}; 
    main_drugs = ["TTV", "SP", "Fefol", "NVP", "Albendazole", "TDF/3TC/EFV"]
    
    @patient.encounters.active.find(:all, :order => "encounter_datetime DESC", 
      :conditions => ["encounter_type = ? AND encounter_datetime >= ? AND encounter_datetime <= ?", 
        EncounterType.find_by_name("TREATMENT").id, @current_range[0]["START"], @current_range[0]["END"]]).each{|e| 
      @drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@drugs[e.encounter_datetime.strftime("%d/%b/%Y")]; 
      @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")] = {} if !@other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")]; 
      e.orders.each{|o| 
        if main_drugs.include?(o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")])          
          if o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")] == "NVP"
            if o.drug_order.drug.name.upcase.include?("ML")
              @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
            else
              @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
            end
          else            
            @drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
          end          
        else
          @other_drugs[e.encounter_datetime.strftime("%d/%b/%Y")][o.drug_order.drug.name[0, o.drug_order.drug.name.index(" ")]] = o.drug_order.amount_needed
        end
      }      
    }
    
    label = ZebraPrinter::StandardLabel.new

    label.draw_line(20,25,800,2,0)
    label.draw_line(20,25,2,280,0)
    label.draw_line(20,305,800,2,0)
    label.draw_line(805,25,2,280,0)
    
    label.draw_line(20,130,800,2,0)
    label.draw_line(20,190,800,2,0)
    
    label.draw_line(72,130,2,175,0)
    label.draw_line(116,130,2,175,0)
    label.draw_line(156,130,2,175,0)
    label.draw_line(192,130,2,175,0)
    label.draw_line(364,130,2,175,0)
    label.draw_line(594,130,2,175,0)
    label.draw_line(706,130,2,175,0)
    label.draw_text("Planned Delivery Place: #{@current_range[0]["PLANNED DELIVERY PLACE"] rescue ""}",28,66,0,2,1,1,false)
    label.draw_text("Bed Net Given: #{@current_range[0]["MOSQUITO NET"] rescue ""}",28,99,0,2,1,1,false)
    label.draw_text("TDF",28,138,0,2,1,1,false)
    label.draw_text("3TC",28,156,0,2,1,1,false)
    label.draw_text("EFV",28,174,0,2,1,1,false)
    label.draw_text("NVP",78,140,0,2,1,1,false)
    label.draw_text("Baby",77,158,0,1,1,1,false)
    label.draw_text("(ml)",77,176,0,1,1,1,false)
    label.draw_text("On",122,140,0,2,1,1,false)
    label.draw_text("CPT",120,158,0,1,1,1,false)
    label.draw_text("On",162,140,0,2,1,1,false)
    label.draw_text("ART",160,158,0,1,1,1,false)
    label.draw_text("Signs/Symptoms",198,140,0,2,1,1,false)
    label.draw_text("Medication/Outcome",370,140,0,2,1,1,false)
    label.draw_text("Next Vis.",600,140,0,2,1,1,false)
    label.draw_text("Date",622,158,0,2,1,1,false)
    label.draw_text("Provider",710,140,0,2,1,1,false)

    @i = 0

    encounters.sort.each do |encounter|
      @i = @i + 1
      
      if encounter[0] == target_date.to_date.strftime("%d/%b/%Y")
        
        tdf = (@drugs[encounter[0]]["TDF/3TC/EFV"].to_i > 0 ? @drugs[encounter[0]]["TDF/3TC/EFV"].to_i : "") rescue ""
          
        label.draw_text(tdf,28,200,0,2,1,1,false)
        
        nvp = (@drugs[encounter[0]]["NVP"].to_i > 0 ? @drugs[encounter[0]]["NVP"].to_i : "") rescue ""
          
        label.draw_text(nvp,77,200,0,2,1,1,false)
      
        cpt = (encounters[encounter[0]]["LAB RESULTS"]["TAKING CO-TRIMOXAZOLE PREVENTIVE THERAPY"].upcase == "YES" ? "Y" : "N") rescue ""
        
        label.draw_text(cpt,124,200,0,2,1,1,false)
        
        art = (encounters[encounter[0]]["LAB RESULTS"]["ON ART"].upcase == "YES" ? "Y" : "N") rescue ""
        
        label.draw_text(art,164,200,0,2,1,1,false)
        
        sign = encounters[encounter[0]]["OBSERVATIONS"]["DIAGNOSIS"].humanize rescue ""
        
        sign = paragraphate(sign.to_s, 13, 5)
        
        (0..(sign.length)).each{|m|
          label.draw_text(sign[m],198,(200 + (18 * m)),0,2,1,1,false)
        }
        
        med = encounters[encounter[0]]["UPDATE OUTCOME"]["OUTCOME"].humanize + "; " rescue ""
        oth = (@other_drugs[encounter[0]].collect{|d, v| 
            "#{d}: #{ (v.to_s.match(/\.[1-9]/) ? v : v.to_i) }"
          }.join("; ")) if @other_drugs[encounter[0]].length > 0 rescue ""
          
        med = paragraphate(med.to_s + oth.to_s, 17, 5)
        
        (0..(med.length)).each{|m|
          label.draw_text(med[m],370,(200 + (18 * m)),0,2,1,1,false)
        }
        
        nex = encounters[encounter[0]]["APPOINTMENT"]["APPOINTMENT DATE"] rescue []
        
        if nex != []
          date = nex.to_date
          nex = []
          nex << date.strftime("%d/")
          nex << date.strftime("%b/")
          nex << date.strftime("%Y")
        end
        
        (0..(nex.length)).each{|m|
          label.draw_text(nex[m],610,(200 + (18 * m)),0,2,1,1,false)
        }
        
        use = encounters[encounter[0]]["USER"] rescue ""
          
        label.draw_text(use,710,200,0,2,1,1,false)
        
      end
    end
    
    label.print(1)
  end
  
  def abbreviate(string)
    string.strip.split(" ").collect{|e| e[0,1].upcase + "." if e[0,1] != ("(")}.join("")
  end
  
  def truncate(string, length = 6)
    string[0,length] + "."
  end
  
  def paragraphate(string, collen = 8, rows = 2)
    arr = []
    
    if string.nil? 
      return arr
    end
    
    string = string.strip
    
    (0..rows).each{|p| 
      if !(string[p*collen,collen]).nil?
        if p == rows
          arr << (string[p*collen,collen] + ".") if !(string[p*collen,collen]).nil?
        elsif string[((p*collen) + collen),1] != " " && !string.strip[((p+1)*collen),collen].nil? && 
            string[(((p+1)*collen) + collen),1] != " "
          arr << (string[p*collen,collen] + "-") if !(string[p*collen,collen]).nil?
        else 
          arr << string[p*collen,collen] if !(string[p*collen,collen]).nil?
        end
      end
    }
    arr
  end
  
end
