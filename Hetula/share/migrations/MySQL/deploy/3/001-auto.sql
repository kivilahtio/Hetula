-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Oct 10 07:51:41 2018
-- 
;
SET foreign_key_checks=0;
--
-- Table: `organization`
--
CREATE TABLE `organization` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(30) NOT NULL,
  `createtime` datetime NOT NULL,
  `updatetime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `organization_name` (`name`)
) ENGINE=InnoDB;
--
-- Table: `permission`
--
CREATE TABLE `permission` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(40) NOT NULL,
  `createtime` datetime NOT NULL,
  `updatetime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `permission_name` (`name`)
) ENGINE=InnoDB;
--
-- Table: `ssn`
--
CREATE TABLE `ssn` (
  `id` integer NOT NULL auto_increment,
  `ssn` varchar(30) NOT NULL,
  `notes` text NULL,
  `createtime` datetime NOT NULL,
  `updatetime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `ssn_ssn` (`ssn`)
) ENGINE=InnoDB;
--
-- Table: `user`
--
CREATE TABLE `user` (
  `id` integer NOT NULL auto_increment,
  `username` varchar(30) NOT NULL,
  `password` varchar(64) NOT NULL,
  `realname` varchar(50) NOT NULL,
  `failed_login_count` integer NOT NULL DEFAULT 0,
  `createtime` datetime NOT NULL,
  `updatetime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE `user_username` (`username`)
) ENGINE=InnoDB;
--
-- Table: `apicredential`
--
CREATE TABLE `apicredential` (
  `id` integer NOT NULL auto_increment,
  `userid` integer NOT NULL,
  `client_id` varchar(32) NOT NULL,
  `client_secret` varchar(32) NOT NULL,
  `client_type` enum('public', 'confidential') NOT NULL,
  `client_redirection_url` varchar(50) NOT NULL,
  `client_website` varchar(50) NOT NULL,
  `createtime` datetime NOT NULL,
  `updatetime` datetime NOT NULL,
  INDEX `apicredential_idx_userid` (`userid`),
  PRIMARY KEY (`id`),
  UNIQUE `apicredential_userid` (`userid`),
  CONSTRAINT `apicredential_fk_userid` FOREIGN KEY (`userid`) REFERENCES `user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
--
-- Table: `log`
--
CREATE TABLE `log` (
  `id` integer NOT NULL auto_increment,
  `userid` integer NULL,
  `organizationid` integer NULL,
  `request` text NOT NULL,
  `description` text NOT NULL,
  `ip` varchar(50) NOT NULL,
  `updatetime` datetime NOT NULL,
  INDEX `log_idx_organizationid` (`organizationid`),
  INDEX `log_idx_userid` (`userid`),
  PRIMARY KEY (`id`),
  CONSTRAINT `log_fk_organizationid` FOREIGN KEY (`organizationid`) REFERENCES `organization` (`id`),
  CONSTRAINT `log_fk_userid` FOREIGN KEY (`userid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB;
--
-- Table: `ssn_organization`
--
CREATE TABLE `ssn_organization` (
  `id` integer NOT NULL auto_increment,
  `ssnid` integer NOT NULL,
  `organizationid` integer NOT NULL,
  INDEX `ssn_organization_idx_organizationid` (`organizationid`),
  INDEX `ssn_organization_idx_ssnid` (`ssnid`),
  PRIMARY KEY (`id`),
  UNIQUE `ssn_organization_ssnid_organizationid` (`ssnid`, `organizationid`),
  CONSTRAINT `ssn_organization_fk_organizationid` FOREIGN KEY (`organizationid`) REFERENCES `organization` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ssn_organization_fk_ssnid` FOREIGN KEY (`ssnid`) REFERENCES `ssn` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_organization`
--
CREATE TABLE `user_organization` (
  `id` integer NOT NULL auto_increment,
  `userid` integer NOT NULL,
  `organizationid` integer NOT NULL,
  INDEX `user_organization_idx_organizationid` (`organizationid`),
  INDEX `user_organization_idx_userid` (`userid`),
  PRIMARY KEY (`id`),
  UNIQUE `user_organization_userid_organizationid` (`userid`, `organizationid`),
  CONSTRAINT `user_organization_fk_organizationid` FOREIGN KEY (`organizationid`) REFERENCES `organization` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_organization_fk_userid` FOREIGN KEY (`userid`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_permission`
--
CREATE TABLE `user_permission` (
  `id` integer NOT NULL auto_increment,
  `userid` integer NOT NULL,
  `permissionid` integer NOT NULL,
  INDEX `user_permission_idx_permissionid` (`permissionid`),
  INDEX `user_permission_idx_userid` (`userid`),
  PRIMARY KEY (`id`),
  UNIQUE `user_permission_userid_permissionid` (`userid`, `permissionid`),
  CONSTRAINT `user_permission_fk_permissionid` FOREIGN KEY (`permissionid`) REFERENCES `permission` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_permission_fk_userid` FOREIGN KEY (`userid`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
