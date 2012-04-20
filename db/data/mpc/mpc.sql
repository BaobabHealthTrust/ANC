
UPDATE `global_property` SET `property_value` = '700' WHERE `property` = 'current_health_center_id';
UPDATE `global_property` SET `property_value` = 'MARTIN PREUSS CENTRE' WHERE `property` = 'current_health_center_name';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'use.user.selected.activities';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'use.filing.number';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'use.extended.staging.questions';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'simple_application_dashboard';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'demographics.middle_name';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'demographics.visit_home_for_treatment';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'demographics.sms_for_TB_therapy';
UPDATE `global_property` SET `property_value` = 'true' WHERE `property` = 'demographics.ground_phone';
UPDATE `global_property` SET `property_value` = 'MPC' WHERE `property` = 'site_prefix';
UPDATE `global_property` SET `property_value` = 'false' WHERE `property` = 'create.from.remote';

INSERT INTO `global_property` (property, property_value, description, uuid) VALUES ("anc_link", 
"localhost:3005", "Link to ART system from ANC system", (SELECT UUID())),
("clinic_days", "Monday,Thursday", "Clinic days", (SELECT UUID())),
("art_link", "localhost:3000", "Link to ART system from ANC system", (SELECT UUID())),
("art_initial_link", "localhost:3000/encounters/new/art_initial?action=show&controller=encounter_types&encounter_type=ART+initial&id=show&patient_id=", 
"Link to ART system from ANC system", (SELECT UUID()));

UPDATE `global_property` SET property_value = "true" WHERE property = "use.user.selected.activities";







