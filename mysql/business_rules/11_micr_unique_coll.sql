-- ============================================================================
-- Additive: UNIQUE (Coll_Type, Coll_Code) so INSERT IGNORE on MICR seed
-- skips an existing collection code on Jenkins re-apply.
-- Does not UPDATE any row. Skips if duplicates already exist.
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

SET @idx := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'COLLECTION_CODE_MICR'
    AND INDEX_NAME = 'uk_micr_coll'
);
SET @dups := (
  SELECT COUNT(*) FROM (
    SELECT Coll_Type, Coll_Code
    FROM COLLECTION_CODE_MICR
    GROUP BY Coll_Type, Coll_Code
    HAVING COUNT(*) > 1
  ) dup_pairs
);
SET @sql := IF(@idx > 0,
  'SELECT ''uk_micr_coll already present'' AS result',
  IF(@dups > 0,
    'SELECT ''uk_micr_coll skipped: duplicate Coll_Type+Coll_Code rows exist'' AS result',
    'ALTER TABLE COLLECTION_CODE_MICR ADD UNIQUE KEY uk_micr_coll (Coll_Type, Coll_Code)'
  )
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
