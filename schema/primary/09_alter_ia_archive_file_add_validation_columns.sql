-- ============================================================================
-- ALTER IA_ARCHIVE_FILE — Add validation columns
-- Run against: primary database
--
-- Backs POST /archive/files/{id}/validate in the Image Archive engine. Until
-- that endpoint existed, a CIFF/COF file could be transmitted with no
-- structural check at all — unlike the Cash Letter engine, whose CL_X9_FILE has
-- carried VALIDATION_STATUS and VALIDATION_DETAILS from the start. These three
-- columns close that asymmetry so the archive side can record a verdict.
--
-- Checks the endpoint performs, for context: the file exists on disk, its
-- on-disk size matches FILE_SIZE_BYTES, and the parsed item count matches
-- ITEM_COUNT. CIFF additionally verifies the trailer checksum; COF verifies
-- that both halves of the .idx/.res pair are present and that the parser
-- reported no structural errors.
--
-- Copied from ECS_ImageArchiveEngine/src/main/resources/db/migration/
-- V2__add_archive_file_validation_columns.sql, per the README rule that a
-- migration needed at tenant creation belongs here as a numbered schema file.
-- The service repo keeps its copy to upgrade already-deployed tenants on the
-- service deploy cycle; this file covers new tenants. Without it a freshly
-- created tenant has no validation columns and the endpoint fails.
--
-- Idempotent, for the same reason as 07: this will also be applied to tenants
-- that already ran the service-repo migration, where a bare ALTER would abort
-- the whole apply-db run.
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @db := DATABASE();

-- VALIDATION_STATUS — VALID | INVALID; NULL means never validated
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE IA_ARCHIVE_FILE ADD COLUMN VALIDATION_STATUS VARCHAR(20) NULL COMMENT ''VALID | INVALID; NULL = not yet validated'' AFTER STATUS',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'IA_ARCHIVE_FILE' AND COLUMN_NAME = 'VALIDATION_STATUS'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- VALIDATION_DETAILS — pass note, or semicolon-joined validation failures
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE IA_ARCHIVE_FILE ADD COLUMN VALIDATION_DETAILS TEXT NULL COMMENT ''Pass note, or semicolon-joined validation failures'' AFTER VALIDATION_STATUS',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'IA_ARCHIVE_FILE' AND COLUMN_NAME = 'VALIDATION_DETAILS'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- VALIDATED_AT — when validation last ran
SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE IA_ARCHIVE_FILE ADD COLUMN VALIDATED_AT TIMESTAMP NULL COMMENT ''When validation last ran'' AFTER VALIDATION_DETAILS',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'IA_ARCHIVE_FILE' AND COLUMN_NAME = 'VALIDATED_AT'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'IA_ARCHIVE_FILE: VALIDATION_STATUS, VALIDATION_DETAILS, VALIDATED_AT present' AS result;
