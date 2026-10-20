-- ============================================================================
-- ALTER FRAUD_WATCH_REF — Add RT column for outclearing enrichment support
-- Run against: business_rules database
--
-- Idempotent: already-provisioned DEV/QA DBs have RT from the first apply.
-- A bare ADD COLUMN aborted Onboard apply-db on duplicate column 'RT' and
-- skipped later files. Match 07/09/10 information_schema guards.
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

SET @db := DATABASE();

-- Step 1: Add RT column if missing (default so existing rows are populated)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE FRAUD_WATCH_REF ADD COLUMN `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT ''026013356'' AFTER `Active`',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'FRAUD_WATCH_REF' AND COLUMN_NAME = 'RT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Step 2: Recreate PK to include RT only when RT is not already in the PK
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE FRAUD_WATCH_REF DROP PRIMARY KEY, ADD PRIMARY KEY (`AccountNumber`, `SerialNumber`, `RT`)',
    'SELECT 1'
  )
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'FRAUD_WATCH_REF' AND CONSTRAINT_NAME = 'PRIMARY' AND COLUMN_NAME = 'RT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Step 3: RT lookup index if missing
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'CREATE INDEX IX_FRAUD_RT ON FRAUD_WATCH_REF (`RT`, `AccountNumber`, `SerialNumber`)',
    'SELECT 1'
  )
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'FRAUD_WATCH_REF' AND INDEX_NAME = 'IX_FRAUD_RT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Step 5: Insert additional fraud watch records for outclearing test scenarios
-- These use transit RTs (checks drawn on other banks, deposited at MCB branch)
INSERT INTO FRAUD_WATCH_REF (`AccountNumber`, `SerialNumber`, `FraudFlagType`, `FraudReasonCode`, `Source`, `CreatedOn`, `Active`, `RT`) VALUES
-- FED origin RT items (transit checks with known fraud)
('9999900005', '500005', 'KNOWN_FRAUD', 'CHECK_WASHING', 'InternalFraudDB', '2026-06-01 10:00:00', 'Y', '021001208'),
('9999900010', '500010', 'PATTERN', 'FORGED_SIGNATURE', 'RiskModel', '2026-06-01 11:00:00', 'Y', '021001208'),
-- JPMC origin RT items
('8888800003', '600003', 'CONFIRMED', 'ALTERED_AMOUNT', 'CaseMgmt', '2026-06-01 12:00:00', 'Y', '031000053'),
('8888800008', '600008', 'PATTERN', 'DUPLICATE_PRESENTMENT', 'RiskModel', '2026-06-01 13:00:00', 'Y', '031000053'),
-- BOA origin RT items
('7777700002', '700002', 'KNOWN_FRAUD', 'CHECK_WASHING', 'InternalFraudDB', '2026-06-01 14:00:00', 'Y', '026009593'),
('7777700007', '700007', 'PATTERN', 'DUP_DEPOSIT', 'RiskModel', '2026-06-01 15:00:00', 'Y', '026009593')
ON DUPLICATE KEY UPDATE FraudFlagType = VALUES(FraudFlagType);

SELECT 'FRAUD_WATCH_REF: RT column, PK, IX_FRAUD_RT present; outclearing test rows upserted' AS result;
