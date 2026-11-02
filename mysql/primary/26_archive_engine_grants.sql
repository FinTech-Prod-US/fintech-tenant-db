-- ============================================================================
-- Grants for the Research Archive Engine (SPEC_14)
-- Run against: primary database (placed here so it runs after every schema it
-- grants on exists: apply-db.py applies mysql/ files in sorted path order).
--
-- The engine uses ONE MySQL user (cross-schema grants, SPEC_14 section 11):
--   * primary / dup_detect / business_rules : read the day being archived
--   * primary.ENGINE_ERROR_LOG              : write engine errors
--   * archive                               : copy (INSERT), force re-run (DELETE),
--                                             sweep log (UPDATE), pruning
--                                             (ALTER + DROP for DROP PARTITION)
--
-- The user is the platform application user created by onboard-tenant.py
-- (MYSQL_APP_USER = cpp_dev). Tenant onboarding already grants it ALL on
-- `<tenant>_%`; these explicit grants keep the archive engine's access correct
-- on instances where the user was created some other way, and document the
-- minimum it needs.
--
-- Idempotent and safe when the user does not exist: a GRANT to a missing user
-- aborts the whole apply-db run on MySQL 8, so each statement runs only if the
-- user is present.
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @app_user := 'cpp_dev';
SET @user_exists := (SELECT COUNT(*) FROM mysql.user WHERE User = @app_user AND Host = '%');

-- Read the source schemas
SET @sql := IF(@user_exists > 0,
  'GRANT SELECT ON `${DB_NAME_PRIMARY}`.* TO ''cpp_dev''@''%''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@user_exists > 0,
  'GRANT SELECT ON `${DB_NAME_DUP_DETECT}`.* TO ''cpp_dev''@''%''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := IF(@user_exists > 0,
  'GRANT SELECT ON `${DB_NAME_BUSINESS_RULES}`.* TO ''cpp_dev''@''%''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Engine error log lives in the primary schema
SET @sql := IF(@user_exists > 0,
  'GRANT INSERT ON `${DB_NAME_PRIMARY}`.`ENGINE_ERROR_LOG` TO ''cpp_dev''@''%''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Archive schema: copy, force re-run, sweep log, partition pruning
SET @sql := IF(@user_exists > 0,
  'GRANT SELECT, INSERT, UPDATE, DELETE, ALTER, DROP ON `${DB_NAME_ARCHIVE}`.* TO ''cpp_dev''@''%''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT IF(@user_exists > 0,
  'archive engine grants applied to cpp_dev',
  'cpp_dev not found - archive engine grants skipped') AS result;
