class Bart2Connection::EncounterType < ActiveRecord::Base
  self.establish_connection :bart2
  set_table_name :encounter_type
  set_primary_key :encounter_type_id
  include Bart2Connection::Openmrs
  has_many :encounters, :class_name => "Bart2Connection::Encounter", :conditions => {:voided => 0}
end
