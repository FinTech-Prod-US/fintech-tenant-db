-- ============================================================================
-- ALTER HOST_BANK — Add POSTAL_CODE
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
--
-- HOST_BANK could describe where the bank is with STREET_ADDRESS,
-- ADDRESS_LINE_2, CITY_NAME, STATE_CODE and COUNTRY_NAME, but had no postal
-- code. That was invisible while the bank's address was only shown on screen.
-- The Customer Advice Engine now composes a return address from these columns
-- and prints it on a mailed notice, where an address without a ZIP is not
-- deliverable, so the column is needed.
--
-- Nullable, because a tenant outside the US may not use one and an advice must
-- still render: the engine joins state and postal code and simply omits
-- whichever is absent.
--
-- Idempotent in the style of 10_item_tracking_and_credit.sql — the column is
-- added only when it is not already there, so this is safe to re-apply.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'HOST_BANK'
    AND COLUMN_NAME = 'POSTAL_CODE'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE HOST_BANK ADD COLUMN POSTAL_CODE VARCHAR(10) NULL COMMENT ''Postal code for the bank return address''',
  'SELECT ''HOST_BANK.POSTAL_CODE exists'' AS result');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Placeholder for local and dev, matching the placeholder street address seeded
-- in 16_seed_host_bank_contact.sql. Only an empty value is filled, so a tenant
-- holding its real postal code is untouched.
UPDATE HOST_BANK
   SET POSTAL_CODE = '10001'
 WHERE POSTAL_CODE IS NULL OR TRIM(POSTAL_CODE) = '';

SELECT 'HOST_BANK.POSTAL_CODE applied' AS result;
