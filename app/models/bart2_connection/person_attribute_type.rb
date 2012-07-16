class Bart2Connection::PersonAttributeType < ActiveRecord::Base
  self.establish_connection :bart2
  set_table_name :person_attribute_type
  set_primary_key :person_attribute_type_id
  include Bart2Connection::Openmrs
  has_many :person_attributes, :class_name => "Bart2Connection::PersonAttribute", :conditions => {:voided => 0}
end