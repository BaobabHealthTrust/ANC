INSERT INTO `global_property` (property, property_value, description, uuid) VALUES ("anc_link", 
"localhost:3005", "Link to ART system from ANC system", (SELECT UUID())),
("clinic_days", "Monday,Thursday", "Clinic days", (SELECT UUID())),
("art_link", "localhost:3000", "Link to ART system from ANC system", (SELECT UUID())),
("art_initial_link", "localhost:3000/encounters/new/art_initial?action=show&controller=encounter_types&encounter_type=ART+initial&id=show&patient_id=", 
"Link to ART system from ANC system", (SELECT UUID()));

UPDATE `global_property` SET property_value = "true" WHERE property = "use.user.selected.activities";







