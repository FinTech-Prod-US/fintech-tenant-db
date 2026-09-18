-- ============================================================================
-- ALTER ITEM_DETAILS_ENRICHED — Add skip tracking columns
-- Run against: primary database
--
-- Supports the operator "skip" action on the four review screens
-- (Image Suspect / Data Correction / Fraud Review / Dup Review). A skip returns
-- the item to its own operator queue with the supplied note so the next operator
-- sees the skip history. CDE tracks item status (approved / skipped / rejected);
-- these columns give the UI quick access to the latest note and a running count
-- without joining ITEM_AUDIT_TRAIL, which keeps the full event history.
--
-- Copied from Accs-Server/database/migrations/
-- 002_add_skip_columns_item_details_enriched.sql. The service repo keeps its
-- copy to upgrade already-deployed tenants on the service deploy cycle; this
-- file is what new tenants get at creation time.
--
-- Idempotent on purpose: unlike 06_alter_fraud_watch_ref_add_rt.sql this file
-- will also be applied to tenants that already ran the Accs-Server migration,
-- and a bare ALTER would abort the whole apply-db run on those.
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @db := DATABASE();

-- SKIP_NOTES — latest skip note (most recent operator's reason)
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN SKIP_NOTES VARCHAR(1000) NULL COMMENT ''Latest operator skip note''',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ITEM_DETAILS_ENRICHED' AND COLUMN_NAME = 'SKIP_NOTES'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- SKIP_COUNT — number of times this item has been skipped
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN SKIP_COUNT INT NOT NULL DEFAULT 0 COMMENT ''Times item has been skipped''',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ITEM_DETAILS_ENRICHED' AND COLUMN_NAME = 'SKIP_COUNT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- SKIP_HISTORY_JSON — append-only JSON array of {operatorId, notes, screen, timestamp}
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN SKIP_HISTORY_JSON TEXT NULL COMMENT ''Append-only JSON array of skip events''',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'ITEM_DETAILS_ENRICHED' AND COLUMN_NAME = 'SKIP_HISTORY_JSON'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'ITEM_DETAILS_ENRICHED altered: SKIP_NOTES, SKIP_COUNT, SKIP_HISTORY_JSON present' AS result;
