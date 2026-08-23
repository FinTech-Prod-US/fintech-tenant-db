-- business_rules schema export
-- Tables: 29

USE ${DB_NAME_BUSINESS_RULES};

-- Table: ALL_ACCOUNT_MASTER (23 rows)
DROP TABLE IF EXISTS `ALL_ACCOUNT_MASTER`;
CREATE TABLE `ALL_ACCOUNT_MASTER` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AccountNumber` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AccountClass` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ProductType` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `BranchCode` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Currency` char(3) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'USD',
  `Status` enum('ACTIVE','CLOSED','FROZEN') COLLATE utf8mb4_unicode_ci NOT NULL,
  `CustomerID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CustomerName` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `PositivePayFlag` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Check_Deposit_Limit` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`RT`,`AccountNumber`),
  KEY `IX_ALL_ACCOUNT_MASTER_ACCT` (`AccountNumber`),
  CONSTRAINT `FK_ALL_ACCOUNT_MASTER_BANK` FOREIGN KEY (`RT`) REFERENCES `BANK_MASTER_RT` (`RT`),
  CONSTRAINT `ALL_ACCOUNT_MASTER_chk_1` CHECK ((`PositivePayFlag` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: API_AGGREGATOR_CONFIG (2 rows)
DROP TABLE IF EXISTS `API_AGGREGATOR_CONFIG`;
CREATE TABLE `API_AGGREGATOR_CONFIG` (
  `ConfigID` int NOT NULL AUTO_INCREMENT,
  `Collection_Code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `BankCode` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ApiAlias` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `BaseUrl` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `HttpMethod` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'GET',
  `AuthType` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'NONE',
  `AuthSecretRef` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RequestTemplate` json DEFAULT NULL,
  `ResponseMapping` json NOT NULL,
  `TimeoutMs` int DEFAULT '5000',
  `RetryCount` int DEFAULT '1',
  `Active` char(1) COLLATE utf8mb4_unicode_ci DEFAULT 'Y',
  `CreatedDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ModifiedDate` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ConfigID`),
  UNIQUE KEY `uk_collection_bank_alias` (`Collection_Code`,`BankCode`,`ApiAlias`),
  KEY `idx_alias` (`ApiAlias`),
  KEY `idx_active` (`Active`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: BANK_ACCOUNT_PRODUCT_MAP (4 rows)
DROP TABLE IF EXISTS `BANK_ACCOUNT_PRODUCT_MAP`;
CREATE TABLE `BANK_ACCOUNT_PRODUCT_MAP` (
  `PRODUCT_MAP_ID` bigint NOT NULL,
  `BANK_ID` bigint NOT NULL,
  `ACCOUNT_PREFIX` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ACCOUNT_SUFFIX` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PRODUCT_CODE` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DERIVED_TRAN_CODE` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ACCS_TRAN_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `EFFECTIVE_DATE` date NOT NULL,
  `EXPIRY_DATE` date DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`PRODUCT_MAP_ID`),
  KEY `FK_PRODUCT_MAP_BANK` (`BANK_ID`),
  KEY `FK_PRODUCT_MAP_ACCS` (`ACCS_TRAN_CODE`),
  CONSTRAINT `FK_PRODUCT_MAP_ACCS` FOREIGN KEY (`ACCS_TRAN_CODE`) REFERENCES `TRAN_CODE_MASTER` (`ACCS_TRAN_CODE`),
  CONSTRAINT `FK_PRODUCT_MAP_BANK` FOREIGN KEY (`BANK_ID`) REFERENCES `BANK_MASTER` (`BANK_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: BANK_MASTER (6 rows)
DROP TABLE IF EXISTS `BANK_MASTER`;
CREATE TABLE `BANK_MASTER` (
  `BANK_ID` bigint NOT NULL,
  `BANK_NAME` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ROUTING_NUMBER` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CORE_SYSTEM_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ENDPOINT_CODE` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`BANK_ID`),
  UNIQUE KEY `UQ_BANK_MASTER_RT` (`ROUTING_NUMBER`),
  KEY `FK_BANK_MASTER_CORE` (`CORE_SYSTEM_CODE`),
  CONSTRAINT `FK_BANK_MASTER_CORE` FOREIGN KEY (`CORE_SYSTEM_CODE`) REFERENCES `CORE_SYSTEM_MASTER` (`CORE_SYSTEM_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: BANK_MASTER_RT (21 rows)
DROP TABLE IF EXISTS `BANK_MASTER_RT`;
CREATE TABLE `BANK_MASTER_RT` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `InclearingFlag` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `OnUsFlag` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Status` enum('ACTIVE','INACTIVE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`RT`),
  CONSTRAINT `BANK_MASTER_RT_chk_1` CHECK ((`InclearingFlag` in (_utf8mb4'Y',_utf8mb4'N'))),
  CONSTRAINT `BANK_MASTER_RT_chk_2` CHECK ((`OnUsFlag` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: BANK_TRAN_CODE_MAP (29 rows)
DROP TABLE IF EXISTS `BANK_TRAN_CODE_MAP`;
CREATE TABLE `BANK_TRAN_CODE_MAP` (
  `BANK_TRAN_MAP_ID` bigint NOT NULL,
  `BANK_ID` bigint NOT NULL,
  `CORE_SYSTEM_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SOURCE_TRAN_CODE` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SOURCE_TRAN_DESC` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ACCS_TRAN_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ALLOWED_FOR_INCLEARING` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `REPAIRABLE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `OVERRIDE_ALLOWED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `EFFECTIVE_DATE` date NOT NULL,
  `EXPIRY_DATE` date DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`BANK_TRAN_MAP_ID`),
  UNIQUE KEY `UQ_BANK_TRAN_CODE` (`BANK_ID`,`SOURCE_TRAN_CODE`,`EFFECTIVE_DATE`),
  KEY `FK_BANK_TRAN_MAP_CORE` (`CORE_SYSTEM_CODE`),
  KEY `FK_BANK_TRAN_MAP_ACCS` (`ACCS_TRAN_CODE`),
  CONSTRAINT `FK_BANK_TRAN_MAP_ACCS` FOREIGN KEY (`ACCS_TRAN_CODE`) REFERENCES `TRAN_CODE_MASTER` (`ACCS_TRAN_CODE`),
  CONSTRAINT `FK_BANK_TRAN_MAP_BANK` FOREIGN KEY (`BANK_ID`) REFERENCES `BANK_MASTER` (`BANK_ID`),
  CONSTRAINT `FK_BANK_TRAN_MAP_CORE` FOREIGN KEY (`CORE_SYSTEM_CODE`) REFERENCES `CORE_SYSTEM_MASTER` (`CORE_SYSTEM_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: COLLECTION_CODE_MASTER (2 rows)
DROP TABLE IF EXISTS `COLLECTION_CODE_MASTER`;
CREATE TABLE `COLLECTION_CODE_MASTER` (
  `COLLECTION_CODE` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DESCRIPTION` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ACTIVE` char(1) COLLATE utf8mb4_unicode_ci DEFAULT 'Y',
  `CREATED_AT` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`COLLECTION_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: COLLECTION_CODE_MICR (4 rows)
DROP TABLE IF EXISTS `COLLECTION_CODE_MICR`;
CREATE TABLE `COLLECTION_CODE_MICR` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Coll_Type` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Coll_Code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Bin#Start` int NOT NULL,
  `Bin#End` int NOT NULL,
  `BatchStart` int NOT NULL,
  `BatchEnd` int NOT NULL,
  `FileDeadline` time DEFAULT NULL,
  `Description` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `work_type` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `idx_micr_lookup` (`Coll_Type`,`Coll_Code`),
  KEY `idx_bin_range` (`Bin#Start`,`Bin#End`),
  KEY `idx_batch_range` (`BatchStart`,`BatchEnd`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: COLLECTION_CODE_ORIGRT_REF (12 rows)
DROP TABLE IF EXISTS `COLLECTION_CODE_ORIGRT_REF`;
CREATE TABLE `COLLECTION_CODE_ORIGRT_REF` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Coll_Type` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `OriginRT` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Collection_Code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `idx_origrt_lookup` (`Coll_Type`,`OriginRT`),
  KEY `idx_collection_code` (`Collection_Code`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: COLLECTION_CODE_UD_REF (17 rows)
DROP TABLE IF EXISTS `COLLECTION_CODE_UD_REF`;
CREATE TABLE `COLLECTION_CODE_UD_REF` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Coll_Type` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `OriginRT` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UserField` varchar(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FedWorkType` varchar(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Coll_Code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `idx_ud_lookup` (`Coll_Type`,`OriginRT`,`UserField`,`FedWorkType`),
  KEY `idx_collection_code` (`Coll_Code`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: COLLECTION_TYPE_MASTER (12 rows)
DROP TABLE IF EXISTS `COLLECTION_TYPE_MASTER`;
CREATE TABLE `COLLECTION_TYPE_MASTER` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `X9_Coll_Type_Ind` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `File_Dest_RT` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Collection_Type` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `idx_collection_type_lookup` (`X9_Coll_Type_Ind`,`File_Dest_RT`),
  KEY `idx_collection_type` (`Collection_Type`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: CORE_SYSTEM_MASTER (6 rows)
DROP TABLE IF EXISTS `CORE_SYSTEM_MASTER`;
CREATE TABLE `CORE_SYSTEM_MASTER` (
  `CORE_SYSTEM_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CORE_SYSTEM_NAME` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DESCRIPTION` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`CORE_SYSTEM_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: ENDPOINT_RESOLUTION_RULES (12 rows)
DROP TABLE IF EXISTS `ENDPOINT_RESOLUTION_RULES`;
CREATE TABLE `ENDPOINT_RESOLUTION_RULES` (
  `RULE_ID` int NOT NULL AUTO_INCREMENT,
  `COLLECTION_CODE` varchar(20) NOT NULL,
  `DIRECTION` varchar(10) NOT NULL,
  `RT_PATTERN` varchar(9) DEFAULT NULL,
  `REJECTION_REASON` varchar(50) DEFAULT NULL,
  `PRIORITY` int NOT NULL DEFAULT '100',
  `ENDPOINT_RT` varchar(9) NOT NULL,
  `ENDPOINT_NETWORK` varchar(10) NOT NULL,
  `CDE_ENDPOINT_RESOLUTION_RULE` json NOT NULL,
  `ACTIVE` tinyint(1) NOT NULL DEFAULT '1',
  `DESCRIPTION` varchar(255) DEFAULT NULL,
  `CREATED_AT` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_AT` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`RULE_ID`),
  KEY `idx_err_lookup` (`COLLECTION_CODE`,`DIRECTION`,`ACTIVE`),
  KEY `idx_err_priority` (`PRIORITY`),
  KEY `idx_err_rt` (`RT_PATTERN`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: ENDPOINT_ROUTE_REF (22 rows)
DROP TABLE IF EXISTS `ENDPOINT_ROUTE_REF`;
CREATE TABLE `ENDPOINT_ROUTE_REF` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `EndpointRT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `EndpointNetwork` enum('FED','SVPCO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `Status` enum('ACTIVE','INACTIVE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`RT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: FRAUD_WATCH_REF (10 rows)
DROP TABLE IF EXISTS `FRAUD_WATCH_REF`;
CREATE TABLE `FRAUD_WATCH_REF` (
  `AccountNumber` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SerialNumber` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FraudFlagType` enum('KNOWN_FRAUD','PATTERN','CONFIRMED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `FraudReasonCode` enum('CHECK_WASHING','DUPLICATE_PRESENTMENT','ALTERED_AMOUNT','FORGED_SIGNATURE','DUP_DEPOSIT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `Source` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Internal',
  `CreatedOn` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Active` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`AccountNumber`,`SerialNumber`),
  KEY `IX_FRAUD_ACTIVE` (`Active`),
  CONSTRAINT `FRAUD_WATCH_REF_chk_1` CHECK ((`Active` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: MICR_PARSE_PROFILE (6 rows)
DROP TABLE IF EXISTS `MICR_PARSE_PROFILE`;
CREATE TABLE `MICR_PARSE_PROFILE` (
  `MICR_PROFILE_ID` bigint NOT NULL,
  `BANK_ID` bigint NOT NULL,
  `PROFILE_NAME` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ONUS_PARSE_METHOD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AUX_ONUS_USED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `TRAN_CODE_REQUIRED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `ACCOUNT_REQUIRED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `SERIAL_REQUIRED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `EFFECTIVE_DATE` date NOT NULL,
  `EXPIRY_DATE` date DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`MICR_PROFILE_ID`),
  KEY `FK_MICR_PROFILE_BANK` (`BANK_ID`),
  CONSTRAINT `FK_MICR_PROFILE_BANK` FOREIGN KEY (`BANK_ID`) REFERENCES `BANK_MASTER` (`BANK_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: MICR_PARSE_REGEX (1 rows)
DROP TABLE IF EXISTS `MICR_PARSE_REGEX`;
CREATE TABLE `MICR_PARSE_REGEX` (
  `REGEX_ID` bigint NOT NULL,
  `MICR_PROFILE_ID` bigint NOT NULL,
  `SOURCE_FIELD` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `REGEX_PATTERN` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ACCOUNT_GROUP_NO` int DEFAULT NULL,
  `TRAN_CODE_GROUP_NO` int DEFAULT NULL,
  `SERIAL_GROUP_NO` int DEFAULT NULL,
  `BRANCH_GROUP_NO` int DEFAULT NULL,
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`REGEX_ID`),
  KEY `FK_MICR_REGEX_PROFILE` (`MICR_PROFILE_ID`),
  CONSTRAINT `FK_MICR_REGEX_PROFILE` FOREIGN KEY (`MICR_PROFILE_ID`) REFERENCES `MICR_PARSE_PROFILE` (`MICR_PROFILE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: MICR_PARSE_SEGMENT (14 rows)
DROP TABLE IF EXISTS `MICR_PARSE_SEGMENT`;
CREATE TABLE `MICR_PARSE_SEGMENT` (
  `SEGMENT_ID` bigint NOT NULL,
  `MICR_PROFILE_ID` bigint NOT NULL,
  `SEGMENT_NAME` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SOURCE_FIELD` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `START_POS` int NOT NULL,
  `SEGMENT_LENGTH` int NOT NULL,
  `DATA_TYPE` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `REQUIRED_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `TRIM_ZERO_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`SEGMENT_ID`),
  KEY `FK_MICR_SEGMENT_PROFILE` (`MICR_PROFILE_ID`),
  CONSTRAINT `FK_MICR_SEGMENT_PROFILE` FOREIGN KEY (`MICR_PROFILE_ID`) REFERENCES `MICR_PARSE_PROFILE` (`MICR_PROFILE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: MOD_ROUTINE (3 rows)
DROP TABLE IF EXISTS `MOD_ROUTINE`;
CREATE TABLE `MOD_ROUTINE` (
  `RoutineID` int NOT NULL AUTO_INCREMENT,
  `Modulus` int NOT NULL,
  `Remainder` int NOT NULL,
  `Weights` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`RoutineID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: POSITIVE_PAY_REF (10 rows)
DROP TABLE IF EXISTS `POSITIVE_PAY_REF`;
CREATE TABLE `POSITIVE_PAY_REF` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AccountNumber` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CheckSerialNumber` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Amount` decimal(12,2) NOT NULL,
  `IssueDate` date NOT NULL,
  `Pay_Status` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`RT`,`AccountNumber`,`CheckSerialNumber`),
  KEY `IX_PP_ACCT_SERIAL` (`AccountNumber`,`CheckSerialNumber`),
  CONSTRAINT `FK_PP_ACCOUNT` FOREIGN KEY (`RT`, `AccountNumber`) REFERENCES `ALL_ACCOUNT_MASTER` (`RT`, `AccountNumber`),
  CONSTRAINT `POSITIVE_PAY_REF_chk_1` CHECK ((`Pay_Status` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: POSTING_CODE_REF (21 rows)
DROP TABLE IF EXISTS `POSTING_CODE_REF`;
CREATE TABLE `POSTING_CODE_REF` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AccountClass` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TranCode` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DebitCreditInd` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `GLAccount` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Active` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `EffectiveDate` date NOT NULL DEFAULT (curdate()),
  PRIMARY KEY (`RT`,`AccountClass`,`TranCode`),
  KEY `IX_POSTING_TRCODE` (`TranCode`),
  CONSTRAINT `POSTING_CODE_REF_chk_1` CHECK ((`DebitCreditInd` in (_utf8mb4'D',_utf8mb4'C'))),
  CONSTRAINT `POSTING_CODE_REF_chk_2` CHECK ((`Active` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: STOP_PAY_REF (10 rows)
DROP TABLE IF EXISTS `STOP_PAY_REF`;
CREATE TABLE `STOP_PAY_REF` (
  `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AccountNumber` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CheckSerialNumber` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `StopDate` date NOT NULL,
  `StopReasonCode` enum('LOST','STOLEN','DECIDE_NOT_TO_PAY') COLLATE utf8mb4_unicode_ci NOT NULL,
  `Active` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`RT`,`AccountNumber`,`CheckSerialNumber`),
  KEY `IX_STOP_ACCT_SERIAL` (`AccountNumber`,`CheckSerialNumber`),
  CONSTRAINT `FK_STOP_ACCOUNT` FOREIGN KEY (`RT`, `AccountNumber`) REFERENCES `ALL_ACCOUNT_MASTER` (`RT`, `AccountNumber`),
  CONSTRAINT `STOP_PAY_REF_chk_1` CHECK ((`Active` in (_utf8mb4'Y',_utf8mb4'N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: TRAN_CODE_MASTER (11 rows)
DROP TABLE IF EXISTS `TRAN_CODE_MASTER`;
CREATE TABLE `TRAN_CODE_MASTER` (
  `ACCS_TRAN_CODE` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ACCS_TRAN_DESC` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ACCOUNT_TYPE` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DR_CR_IND` char(1) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ITEM_CLASS` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FORWARD_PRESENT_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `RETURN_ITEM_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `ADJUSTMENT_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `COMMERCIAL_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `CONSUMER_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `ACTIVE_FLAG` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y',
  `CREATED_TS` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ACCS_TRAN_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: WORKFLOW_MASTER (4 rows)
DROP TABLE IF EXISTS `WORKFLOW_MASTER`;
CREATE TABLE `WORKFLOW_MASTER` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Collection_Code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FDE_JSON_Rule` json DEFAULT NULL,
  `IDE_JSON_Rule` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CDE_JSON_Rule` json DEFAULT NULL,
  `IQV_JSON_Rule` json DEFAULT NULL,
  `DQV_JSON_Rule` json DEFAULT NULL,
  `CL_JSON_Rule` json DEFAULT NULL,
  `ImageArchive_JSON_Rule` json DEFAULT NULL,
  `CDE_Endpoint_Resolution_Rule` json DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Collection_Code` (`Collection_Code`),
  KEY `idx_collection_code` (`Collection_Code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: WORKFLOW_MASTER_AUDIT (5 rows)
DROP TABLE IF EXISTS `WORKFLOW_MASTER_AUDIT`;
CREATE TABLE `WORKFLOW_MASTER_AUDIT` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `operation` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Id` int DEFAULT NULL,
  `Collection_Code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `FDE_JSON_Rule` json DEFAULT NULL,
  `IDE_JSON_Rule` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `audit_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `audit_user` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`audit_id`),
  KEY `idx_audit_collection_code` (`Collection_Code`),
  KEY `idx_audit_timestamp` (`audit_timestamp`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: cheques (0 rows)
DROP TABLE IF EXISTS `cheques`;
CREATE TABLE `cheques` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `account_number` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(38,2) DEFAULT NULL,
  `bank_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cheque_number` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payee_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reject_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('PENDING','PROCESSING','VERIFIED','REJECTED','FLAGGED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  `reviewed_by` bigint DEFAULT NULL,
  `uploaded_by` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: users (4 rows)
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('ADMIN','OPERATOR','AUDITOR') COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_6dotkott2kjsp8vw4d0m25fb7` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: v_collection_code_mappings (18 rows)
DROP TABLE IF EXISTS `v_collection_code_mappings`;
CREATE ALGORITHM=UNDEFINED DEFINER=`cpp_dev`@`%` SQL SECURITY DEFINER VIEW `v_collection_code_mappings` AS select `cor`.`Coll_Type` AS `Coll_Type`,`cor`.`OriginRT` AS `OriginRT`,`cor`.`Collection_Code` AS `Primary_Collection_Code`,`cor`.`Description` AS `Primary_Description`,`cud`.`Coll_Code` AS `Secondary_Collection_Code`,`cud`.`Description` AS `Secondary_Description`,`cud`.`UserField` AS `UserField` from (`COLLECTION_CODE_ORIGRT_REF` `cor` left join `COLLECTION_CODE_UD_REF` `cud` on(((`cor`.`Coll_Type` = `cud`.`Coll_Type`) and (`cor`.`OriginRT` = `cud`.`OriginRT`))));

-- Table: v_workflow_rules (4 rows)
DROP TABLE IF EXISTS `v_workflow_rules`;
CREATE ALGORITHM=UNDEFINED DEFINER=`cpp_dev`@`%` SQL SECURITY DEFINER VIEW `v_workflow_rules` AS select `wm`.`Id` AS `Id`,`wm`.`Collection_Code` AS `Collection_Code`,`wm`.`Name` AS `Name`,`wm`.`FDE_JSON_Rule` AS `FDE_JSON_Rule`,`wm`.`IDE_JSON_Rule` AS `IDE_JSON_Rule`,`wm`.`created_at` AS `created_at`,`wm`.`updated_at` AS `updated_at` from `WORKFLOW_MASTER` `wm`;

