-- ============================================================================
-- EXCEPTION_MASTER — columns used by the test-deck builder seed
-- Adds exception_id and description. Widens priority_band so CRITICAL/HIGH/
-- MEDIUM/LOW fit alongside the existing P0–P4 values.
-- exception_code stays the primary key (workflow and X9 maps reference it).
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @has_desc := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND COLUMN_NAME = 'description'
);
SET @sql := IF(@has_desc = 0,
  'ALTER TABLE EXCEPTION_MASTER ADD COLUMN description VARCHAR(255) NULL AFTER default_queue',
  'SELECT ''EXCEPTION_MASTER.description exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_id := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND COLUMN_NAME = 'exception_id'
);
SET @sql := IF(@has_id = 0,
  'ALTER TABLE EXCEPTION_MASTER ADD COLUMN exception_id INT NULL FIRST',
  'SELECT ''EXCEPTION_MASTER.exception_id exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @n := 0;
UPDATE EXCEPTION_MASTER
SET exception_id = (@n := @n + 1)
WHERE exception_id IS NULL
ORDER BY exception_code;

SET @id_extra := (
  SELECT EXTRA FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND COLUMN_NAME = 'exception_id'
);
SET @has_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND INDEX_NAME = 'uk_exception_id'
);
SET @sql := IF(@id_extra LIKE '%auto_increment%' AND @has_uk > 0,
  'SELECT ''EXCEPTION_MASTER.exception_id already auto_increment'' AS result',
  'ALTER TABLE EXCEPTION_MASTER MODIFY exception_id INT NOT NULL AUTO_INCREMENT, ADD UNIQUE KEY uk_exception_id (exception_id)');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @band_type := (
  SELECT DATA_TYPE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND COLUMN_NAME = 'priority_band'
);
SET @sql := IF(@band_type = 'varchar',
  'SELECT ''EXCEPTION_MASTER.priority_band already varchar'' AS result',
  'ALTER TABLE EXCEPTION_MASTER MODIFY priority_band VARCHAR(20) NOT NULL');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @cat_nullable := (
  SELECT IS_NULLABLE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'EXCEPTION_MASTER' AND COLUMN_NAME = 'exception_category'
);
SET @sql := IF(@cat_nullable = 'YES',
  'SELECT ''EXCEPTION_MASTER.exception_category already nullable'' AS result',
  'ALTER TABLE EXCEPTION_MASTER MODIFY exception_category ENUM(''FRAUD'',''POSTING'',''IMAGE'') NULL');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'EXCEPTION_MASTER test-deck columns ready' AS result;
