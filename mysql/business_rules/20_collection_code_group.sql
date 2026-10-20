-- ============================================================================
-- COLLECTION_CODE_GROUP — static governance table mapping each collection code to
-- its functional group. Source of truth for the DupDetect group-segregation feature.
-- The DupDetect engine does NOT read this table at runtime; it is the human-maintained
-- reference used to author/verify the DUP_JSON.matchCollectionCodes lists in
-- dup_detect.WORKFLOW_MASTER (see dup_detect/04_dup_group_match_seed.sql).
-- Run against: business_rules (${DB_NAME_BUSINESS_RULES})
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

CREATE TABLE IF NOT EXISTS COLLECTION_CODE_GROUP (
  COLLECTION_CODE VARCHAR(10) NOT NULL,
  GROUP_NAME      VARCHAR(20) NOT NULL,
  DESCRIPTION     VARCHAR(100) NULL,
  ACTIVE_FLAG     TINYINT(1) NOT NULL DEFAULT 1,
  CREATED_AT      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED_AT      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (COLLECTION_CODE),
  KEY idx_ccg_group (GROUP_NAME)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO COLLECTION_CODE_GROUP (COLLECTION_CODE, GROUP_NAME, DESCRIPTION) VALUES
  ('INCLFF',   'INCLEARING',    'Inclearing forward - Fed'),
  ('INCLFB',   'INCLEARING',    'Inclearing forward - Bank'),
  ('INCLRF',   'EXCEPTION_IN',  'Exception In / return - Fed'),
  ('INCLRB',   'EXCEPTION_IN',  'Exception In / return - Bank (SVPCO)'),
  ('OUTCLFBR', 'OUTCLEARING',   'Outclearing forward - Branch'),
  ('OUTCLFATM','OUTCLEARING',   'Outclearing forward - ATM'),
  ('OUTCLFMOB','OUTCLEARING',   'Outclearing forward - Mobile'),
  ('OUTCLFRDC','OUTCLEARING',   'Outclearing forward - RDC'),
  ('OUTCLFLBX','OUTCLEARING',   'Outclearing forward - Lockbox'),
  ('OUTCLFCOR','OUTCLEARING',   'Outclearing forward - Correspondent'),
  ('OUTCLRDDA','EXCEPTION_OUT', 'Exception Out / return - DDA'),
  ('OUTCLRCD', 'EXCEPTION_OUT', 'Exception Out / return - Card'),
  ('OUTCLRLN', 'EXCEPTION_OUT', 'Exception Out / return - Loan')
ON DUPLICATE KEY UPDATE GROUP_NAME=VALUES(GROUP_NAME), DESCRIPTION=VALUES(DESCRIPTION), ACTIVE_FLAG=1;

SELECT 'COLLECTION_CODE_GROUP ready' AS result;
