class Bart2Connection::PersonAttribute < ActiveRecord::Base
  self.establish_connection :bart2
  set_table_name "person_attribute"
  set_primary_key "person_attribute_id"
  include Bart2Connection::Openmrs

  belongs_to :type, :class_name => "Bart2Connection::PersonAttributeType", :foreign_key => :person_attribute_type_id, :conditions => {:retired => 0}
  belongs_to :person, :class_name => "Bart2Connection::Person", :foreign_key => :person_id, :conditions => {:voided => 0}
end
