-- ============================================================================
-- ITEM_DETAILS.SYNTHESIZED_CREDIT marker column (SPEC_09 Phase 2)
-- Marks the ACCS-synthesized inclearing CL-header balancing credit item so CDE
-- can skip IQV/DQV/BR + endpoint routing on it and exclude it from completion
-- counts. 1 = synthesized balancing credit; 0 = real X9 item.
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ITEM_DETAILS'
    AND COLUMN_NAME = 'SYNTHESIZED_CREDIT'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE ITEM_DETAILS ADD COLUMN SYNTHESIZED_CREDIT TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = ACCS-synthesized inclearing CL-header balancing credit, not a real X9 item (SPEC_09 Phase 2)''',
  'SELECT ''ITEM_DETAILS.SYNTHESIZED_CREDIT exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'item details synthesized credit column applied' AS result;
