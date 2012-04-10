-- MySQL dump 10.13  Distrib 5.1.61, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: bart2_development
-- ------------------------------------------------------
-- Server version	5.1.61-0ubuntu0.11.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `anc_tasks`
--

DROP TABLE IF EXISTS `anc_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `anc_tasks` (
  `task_id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `encounter_type` varchar(255) DEFAULT NULL,
  `description` text,
  `location` varchar(255) DEFAULT NULL,
  `gender` varchar(50) DEFAULT NULL,
  `has_obs_concept_id` int(11) DEFAULT NULL,
  `has_obs_value_coded` int(11) DEFAULT NULL,
  `has_obs_value_drug` int(11) DEFAULT NULL,
  `has_obs_value_datetime` datetime DEFAULT NULL,
  `has_obs_value_numeric` double DEFAULT NULL,
  `has_obs_value_text` text,
  `has_obs_scope` text,
  `has_program_id` int(11) DEFAULT NULL,
  `has_program_workflow_state_id` int(11) DEFAULT NULL,
  `has_identifier_type_id` int(11) DEFAULT NULL,
  `has_relationship_type_id` int(11) DEFAULT NULL,
  `has_order_type_id` int(11) DEFAULT NULL,
  `has_encounter_type_today` varchar(255) DEFAULT NULL,
  `skip_if_has` smallint(6) DEFAULT '0',
  `sort_weight` double DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `voided` smallint(6) DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  `uuid` char(38) DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `task_creator` (`creator`),
  KEY `user_who_voided_task` (`voided_by`),
  KEY `user_who_changed_task` (`changed_by`),
  CONSTRAINT `task__creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user__who_changed__task` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user__who_voided__task` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `anc_tasks`
--

LOCK TABLES `anc_tasks` WRITE;
/*!40000 ALTER TABLE `anc_tasks` DISABLE KEYS */;
INSERT INTO `anc_tasks` VALUES (96,'/prescriptions/ttv/?patient_id={patient}','DISPENSING','Ask if patient is receiving TTV today','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'DISPENSING',0,2,1,'2012-03-29 11:06:49',0,1,NULL,'temp',1,NULL,'76f6504e-797e-11e1-851f-001dbaee2e53'),(97,'/encounters/new/vitals/?patient_id={patient}&weight=1&height=1','VITALS','Ask Vitals when patient comes in','*',NULL,5089,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2012-03-29 00:00:00',0,NULL,NULL,NULL,1,NULL,'bd516c82-79a0-11e1-851f-001dbaee2e53'),(99,'/patients/show/{patient}',NULL,'Patient Dashboard','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,16,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'780748f6-7ca0-11e1-ab6d-001dbaee2e53'),(100,'/patients/visit_type/?patient_id={patient}','ANC VISIT TYPE','Anc Visit Pregnancy Number','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'ANC VISIT TYPE',0,4,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'522edb6c-7cb4-11e1-ab6d-001dbaee2e53'),(101,'/patients/obstetric_history/?patient_id={patient}','OBSTETRIC HISTORY','Obstetric History Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXISTS',NULL,NULL,NULL,NULL,NULL,'',0,5,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'0beebfc2-7cb5-11e1-ab6d-001dbaee2e53'),(102,'/patients/medical_history/?patient_id={patient}','MEDICAL HISTORY','Medical History Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXISTS',NULL,NULL,NULL,NULL,NULL,'',0,6,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'6d0629b2-7cb5-11e1-ab6d-001dbaee2e53'),(103,'/patients/surgical_history/?patient_id={patient}','SURGICAL HISTORY','Surgical History Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXISTS',NULL,NULL,NULL,NULL,NULL,'',0,7,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'bf96599a-7cb5-11e1-ab6d-001dbaee2e53'),(104,'/patients/social_history/?patient_id={patient}','SOCIAL HISTORY','Social History Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EXISTS',NULL,NULL,NULL,NULL,NULL,'',0,8,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'04a2c168-7cb6-11e1-ab6d-001dbaee2e53'),(105,'/encounters/new/lab_results?patient_id={patient}','LAB RESULTS','Lab Results Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'LAB RESULTS',0,9,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'ec515adc-7cc1-11e1-ab6d-001dbaee2e53'),(106,'/patients/observations/?patient_id={patient}','OBSERVATIONS','ANC Examinations Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'OBSERVATIONS',0,10,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'a8d9defa-7cc6-11e1-ab6d-001dbaee2e53'),(107,'/patients/current_pregnancy/?patient_id={patient}','CURRENT PREGNANCY','Current Pregnancy One Off Questions','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'',0,11,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'44948758-7cc9-11e1-ab6d-001dbaee2e53'),(108,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','Next Appointment Date','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'APPOINTMENT',0,12,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'937a253a-7cc9-11e1-ab6d-001dbaee2e53'),(109,'/prescriptions/give_drugs/?patient_id={patient}','TREATMENT','Medications given to client','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'',0,13,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'002992ba-7cca-11e1-ab6d-001dbaee2e53'),(110,'/patients/outcome/?patient_id={patient}','UPDATE OUTCOME','Outcome update','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'UPDATE OUTCOME',0,14,1,'2012-04-02 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'b5d0e89c-7ccb-11e1-ab6d-001dbaee2e53'),(111,'/encounters/new/vitals/?patient_id={patient}&bp=1','VITALS','Ask BP','*',NULL,5085,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,3,1,'2012-04-10 00:00:00',0,NULL,NULL,NULL,NULL,NULL,'fe9f4fb6-82e6-11e1-9a15-001dbaee2e53');
/*!40000 ALTER TABLE `anc_tasks` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-04-10 13:10:02
