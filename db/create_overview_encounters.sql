DELETE FROM global_property WHERE property = "statistics.show_encounter_types";

INSERT INTO global_property (property, property_value, description) VALUES ("statistics.show_encounter_types", "REGISTRATION,APPOINTMENT,CURRENT PREGNANCY,TREATMENT,UPDATE OUTCOME,OBSERVATIONS,VITALS,LAB RESULTS", "Maternity Encounter Types") ON DUPLICATE KEY UPDATE property = "statistics.show_encounter_types";
