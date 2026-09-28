-- ============================================================================
-- ITEM_DETAILS / ITEM_DETAILS_ENRICHED columns used by Accs-Server and FDE
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ITEM_DETAILS_ENRICHED'
    AND COLUMN_NAME = 'PAYMENT_TRACKING_NUMBER'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN PAYMENT_TRACKING_NUMBER VARCHAR(64) NULL',
  'SELECT ''ITEM_DETAILS_ENRICHED.PAYMENT_TRACKING_NUMBER exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ITEM_DETAILS'
    AND COLUMN_NAME = 'PAYMENT_TRACKING_NUMBER'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE ITEM_DETAILS ADD COLUMN PAYMENT_TRACKING_NUMBER VARCHAR(64) NULL',
  'SELECT ''ITEM_DETAILS.PAYMENT_TRACKING_NUMBER exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ITEM_DETAILS'
    AND COLUMN_NAME = 'DEBIT_CREDIT_IND'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE ITEM_DETAILS ADD COLUMN DEBIT_CREDIT_IND CHAR(1) NULL',
  'SELECT ''ITEM_DETAILS.DEBIT_CREDIT_IND exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'item tracking and credit columns applied' AS result;
