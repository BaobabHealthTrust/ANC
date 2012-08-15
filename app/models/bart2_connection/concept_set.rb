class Bart2Connection::ConceptSet < ActiveRecord::Base
  self.establish_connection :bart2
  set_table_name :concept_set
  set_primary_key :concept_set_id
  include Bart2Connection::Openmrs
  belongs_to :set, :class_name => 'Bart2Connection::Concept', :conditions => {:retired => 0}
  belongs_to :concept, :class_name => "Bart2Connection::Concept", :conditions => {:retired => 0}
end
