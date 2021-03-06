DROP SCHEMA IF EXISTS dbversion;
CREATE SCHEMA dbversion;
USE dbversion;

DROP TABLE IF EXISTS installed;
CREATE TABLE installed (
`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
version VARCHAR(8) NOT NULL,
date TIMESTAMP NOT NULL
);


INSERT INTO `installed` VALUES (1, '01', CURRENT_TIMESTAMP);
INSERT INTO `installed` VALUES (2, '012', CURRENT_TIMESTAMP);
