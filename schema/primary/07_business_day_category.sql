-- ============================================================================
-- BUSINESS_DAY — one open row per (BDAY_ID, CATEGORY)
-- INCLFF and OUTCLFBR can share a calendar date. Existing rows stay.
-- No DROP TABLE. Child FKs on BDAY_ID stay: the new unique key starts with BDAY_ID.
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @has_id := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'BUSINESS_DAY' AND COLUMN_NAME = 'ID'
);
SET @sql := IF(@has_id = 0,
  'ALTER TABLE BUSINESS_DAY ADD COLUMN ID BIGINT NULL',
  'SELECT ''BUSINESS_DAY.ID exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE BUSINESS_DAY SET ID = BDAY_ID WHERE ID IS NULL;

SET @has_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'BUSINESS_DAY'
    AND INDEX_NAME = 'uk_business_day_category'
);
SET @sql := IF(@has_uk = 0,
  'ALTER TABLE BUSINESS_DAY ADD UNIQUE KEY uk_business_day_category (BDAY_ID, CATEGORY)',
  'SELECT ''uk_business_day_category exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @pk_cols := (
  SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION)
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'BUSINESS_DAY'
    AND CONSTRAINT_NAME = 'PRIMARY'
);
SET @sql := IF(@pk_cols = 'ID',
  'SELECT ''BUSINESS_DAY primary key is already ID'' AS result',
  'ALTER TABLE BUSINESS_DAY MODIFY ID BIGINT NOT NULL, DROP PRIMARY KEY, ADD PRIMARY KEY (ID)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @id_extra := (
  SELECT EXTRA FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'BUSINESS_DAY' AND COLUMN_NAME = 'ID'
);
SET @sql := IF(@id_extra LIKE '%auto_increment%',
  'SELECT ''BUSINESS_DAY.ID already auto_increment'' AS result',
  'ALTER TABLE BUSINESS_DAY MODIFY ID BIGINT NOT NULL AUTO_INCREMENT');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'BUSINESS_DAY unique (BDAY_ID, CATEGORY) ready' AS result;
