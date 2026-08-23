-- ============================================================================
-- ALTER FRAUD_WATCH_REF — Add RT column for outclearing enrichment support
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

-- Step 1: Add RT column with a default so existing rows get populated immediately
ALTER TABLE FRAUD_WATCH_REF
  ADD COLUMN `RT` char(9) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '026013356'
  AFTER `Active`;

-- Step 2: Drop old primary key and recreate with RT included
ALTER TABLE FRAUD_WATCH_REF
  DROP PRIMARY KEY,
  ADD PRIMARY KEY (`AccountNumber`, `SerialNumber`, `RT`);

-- Step 3: Add index for RT-based lookups (outclearing flow: WHERE RT = ? AND AccountNumber = ? AND SerialNumber = ?)
CREATE INDEX IX_FRAUD_RT ON FRAUD_WATCH_REF (`RT`, `AccountNumber`, `SerialNumber`);

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

SELECT 'FRAUD_WATCH_REF altered: RT column added, 6 new outclearing test rows inserted' AS result;
