-- ============================================================================
-- ARCHIVE_SWEEP_LOG — sweep watermark, audit and legal-hold gate (SPEC_14 7.3)
-- NOT partitioned: it is tiny, and it must survive partition pruning (the
-- pruning job reads LEGAL_HOLD here before dropping a month).
--
-- PK DECISION: (BDAY_ID, CATEGORY).
--   Operational BUSINESS_DAY is unique on (BDAY_ID, CATEGORY), NOT on BDAY_ID
--   (07_business_day_category.sql: INCLFF and OUTCLFBR can share a BDAY_ID/date,
--   and the source PK was changed to the surrogate ID). A BDAY_ID-only PK would
--   let one category's sweep mask the other. BUSINESS_DAY.CATEGORY is nullable
--   in the source, so the log stores NOT NULL DEFAULT '' (empty string = no
--   category) so it can sit in the PK. The SPEC_14 6.3 "find work" query must
--   therefore join on BDAY_ID AND COALESCE(b.CATEGORY, '') = s.CATEGORY.
-- ============================================================================
USE ${DB_NAME_ARCHIVE};

CREATE TABLE IF NOT EXISTS `ARCHIVE_SWEEP_LOG` (
  `BDAY_ID` bigint NOT NULL,
  `CATEGORY` varchar(10) NOT NULL DEFAULT '' COMMENT 'BUSINESS_DAY.CATEGORY, empty string when NULL in source',
  `BUSINESS_DATE` date NOT NULL COMMENT 'Equals ARCHIVE_BUS_DATE of the rows written for this day',
  `STARTED_AT` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ARCHIVED_AT` timestamp NULL DEFAULT NULL COMMENT 'Set when STATUS becomes ARCHIVED',
  `STATUS` varchar(10) NOT NULL DEFAULT 'RUNNING' COMMENT 'RUNNING | ARCHIVED | FAILED',
  `ROW_COUNTS` json DEFAULT NULL COMMENT 'Per-table copied row counts',
  `CHECKSUM` varchar(64) DEFAULT NULL,
  `LEGAL_HOLD` tinyint NOT NULL DEFAULT 0 COMMENT '1 = exempt from retention pruning (month partition retained)',
  `ERROR_DETAILS` text,
  PRIMARY KEY (`BDAY_ID`, `CATEGORY`),
  KEY `idx_asl_business_date` (`BUSINESS_DATE`),
  KEY `idx_asl_status` (`STATUS`),
  KEY `idx_asl_legal_hold` (`LEGAL_HOLD`, `BUSINESS_DATE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'ARCHIVE_SWEEP_LOG ready' AS result;
