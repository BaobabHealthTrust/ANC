class Bart2Connection::Order < ActiveRecord::Base
  set_table_name :orders
  set_primary_key :order_id
  include Bart2Connection::Openmrs
  belongs_to :order_type, :class_name => "Bart2Connection::OrderType", :conditions => {:retired => 0}
  belongs_to :concept, :class_name => "Bart2Connection::Concept", :conditions => {:retired => 0}
  belongs_to :encounter, :class_name => "Bart2Connection::Encounter", :conditions => {:voided => 0}
  belongs_to :patient, :class_name => "Bart2Connection::Patient", :conditions => {:voided => 0}
  belongs_to :provider, :foreign_key => 'orderer', :class_name => 'Bart2Connection::User', :conditions => {:voided => 0}
  belongs_to :observation, :foreign_key => 'obs_id', :class_name => 'Bart2Connection::Observation', :conditions => {:voided => 0}
  has_one :drug_order, :class_name => "Bart2Connection::DrugOrder" # no default scope
  
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()', :include => :encounter
  named_scope :historical, :conditions => 'DATE(encounter.encounter_datetime) <> CURRENT_DATE()', :include => :encounter
  named_scope :unfinished, :conditions => ['discontinued = 0 AND auto_expire_date > NOW()']
  named_scope :finished, :conditions => ['discontinued = 1 OR auto_expire_date < NOW()']
  named_scope :arv, lambda {|order|
    arv_concept = ConceptName.find_by_name("ANTIRETROVIRAL DRUGS").concept_id
    arv_drug_concepts = ConceptSet.all(:conditions => ['concept_set = ?', arv_concept])
    {:conditions => ['concept_id IN (?)', arv_drug_concepts.map(&:concept_id)]}
  }
  named_scope :labs, :conditions => ['drug_order.drug_inventory_id is NULL'], :include => :drug_order
  named_scope :prescriptions, :conditions => ['drug_order.drug_inventory_id is NOT NULL'], :include => :drug_order
  
  def after_void(reason = nil)
    # TODO Should we be voiding the associated meta obs that point back to this?
  end

  def to_s
    "#{drug_order}"
  end
  
end
