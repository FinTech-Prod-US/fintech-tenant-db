-- ============================================================================
-- ALTER HOST_BANK — Add LOGO_URL
-- Run against: primary database
--
-- The bank's name already reaches the UI from this table, via the auth response
-- (Accs-Server auth.service.ts -> SELECT BANK_NAME FROM HOST_BANK). Its logo did
-- not: the header rendered a static /logo.webp baked into the Accs-UI image at
-- build time, so every tenant got the same logo no matter what this row said.
--
-- LOGO_URL closes that split, so the whole bank identity comes from one place.
--
-- Accepted values:
--   * an S3 object key, with or without the tenant prefix
--       MCB-026013356/branding/logo.webp
--       branding/logo.webp
--     Accs-Server streams it through GET /api/auth/bank-logo, because the bucket
--     is not reachable from a browser in any environment we deploy to.
--   * a fully-qualified http(s) URL, returned to the UI as-is for a tenant that
--     already hosts its logo on a CDN.
--   * NULL — the UI falls back to its bundled /logo.webp, which is the current
--     behaviour, so leaving this unset changes nothing.
--
-- Deliberately a key rather than the bytes: the auth response is fetched on every
-- /me call, and inlining an image there would put it on the wire each time.
--
-- Idempotent, matching 07 and 09 — this is applied both to new tenants and to
-- already-provisioned ones, where a bare ALTER would abort the whole apply-db run.
-- ============================================================================

USE ${DB_NAME_PRIMARY};

SET @db := DATABASE();

SET @sql := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE HOST_BANK ADD COLUMN LOGO_URL VARCHAR(512) NULL COMMENT ''S3 key or absolute http(s) URL for the bank logo; NULL = use the UI default'' AFTER BANK_NAME',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'HOST_BANK' AND COLUMN_NAME = 'LOGO_URL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'HOST_BANK: LOGO_URL present' AS result;
