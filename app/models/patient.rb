class Patient < ActiveRecord::Base
  set_table_name "patient"
  set_primary_key "patient_id"
  include Openmrs

  has_one :person, :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :patient_identifiers, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :patient_programs, :conditions => {:voided => 0}
  has_many :programs, :through => :patient_programs
  has_many :relationships, :foreign_key => :person_a, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :orders, :conditions => {:voided => 0}
  has_many :encounters, :conditions => {:voided => 0} do 
    def find_by_date(encounter_date)
      encounter_date = Date.today unless encounter_date
      find(:all, :conditions => ["encounter_datetime BETWEEN ? AND ?", 
          encounter_date.to_date.strftime('%Y-%m-%d 00:00:00'),
          encounter_date.to_date.strftime('%Y-%m-%d 23:59:59')
        ]) # Use the SQL DATE function to compare just the date part
    end
  end

  def after_void(reason = nil)
    self.person.void(reason) rescue nil
    self.patient_identifiers.each {|row| row.void(reason) }
    self.patient_programs.each {|row| row.void(reason) }
    self.orders.each {|row| row.void(reason) }
    self.encounters.each {|row| row.void(reason) }
  end

  def get_full_identifier(identifier)
    PatientIdentifier.find(:first,:conditions =>["voided = 0 AND identifier_type = ? AND patient_id = ?",
        PatientIdentifierType.find_by_name(identifier).id, self.patient.id]) rescue nil
  end

  def set_identifier(identifier, value)
    PatientIdentifier.create(:patient_id => self.patient.patient_id, :identifier => value,
      :identifier_type => (PatientIdentifierType.find_by_name(identifier).id))
  end
  def national_id(force = true)
    #raise PatientIdentifierType.find_by_name("National Id").id.to_yaml
    id = self.patient_identifiers.find_by_identifier_type(PatientIdentifierType.find_by_name("National id").id).identifier rescue nil
    return id unless force
    id ||= PatientIdentifierType.find_by_name("National id").next_identifier(:patient => self).identifier
    id
  end

  def lmp(today = Date.today)
    self.encounters.collect{|e|
      e.observations.collect{|o|
        (o.answer_string.to_date rescue nil) if o.concept.concept_names.map(& :name).include?("Date of last menstrual period") && o.answer_string.to_date <= today.to_date
      }.compact
    }.uniq.delete_if{|x| x == []}.flatten.max
  end

  def hiv_positive?
    
    self.encounters.find(:all, :select => ["obs.value_coded, obs.value_text"], :joins => [:observations],
      :conditions => ["encounter.encounter_type = ? AND obs.concept_id = ?",
        EncounterType.find_by_name("LAB RESULTS").id, ConceptName.find_by_name("HIV STATUS").concept_id]).collect{|ob|
      (Concept.find(ob.value_coded).name.name.downcase.strip rescue nil) || ob.value_text.downcase.strip}.include?("positive") rescue false
   
  end

end
