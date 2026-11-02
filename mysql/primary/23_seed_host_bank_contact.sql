-- ============================================================================
-- HOST_BANK — fill in the bank's own street address and support phone.
--
-- These two columns were NULL, and the Customer Advice Engine had the values
-- hardcoded in Java instead ("100 Main Street, New York, NY 10001" and
-- "1-800-555-0100"). That put an invented address and phone on every printed
-- customer advice, and on a multi-tenant platform it meant any tenant would
-- receive MCB's details. The engine now reads HOST_BANK, so the values belong
-- here.
--
-- Only NULL or empty columns are filled. A tenant that already holds its real
-- address and phone is left untouched, so this is safe to apply anywhere and
-- safe to re-apply.
--
-- *** The values written here are PLACEHOLDERS for local and dev use. *** They
-- are the same strings the engine used to hardcode, chosen so the rendered
-- letter is unchanged by the move and the plumbing can be verified on its own.
-- Before any advice is mailed, a real environment must carry the bank's own
-- published street address and customer support number.
--
-- Known gap: HOST_BANK has STREET_ADDRESS, ADDRESS_LINE_2, CITY_NAME,
-- STATE_CODE and COUNTRY_NAME but NO postal code column, so a composed return
-- address cannot carry a ZIP. That needs addressing before real mail.
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================
USE ${DB_NAME_PRIMARY};

UPDATE HOST_BANK
   SET STREET_ADDRESS = '100 Main Street'
 WHERE STREET_ADDRESS IS NULL OR TRIM(STREET_ADDRESS) = '';

UPDATE HOST_BANK
   SET CONTACT_PHONE_NUMBER = '1-800-555-0100'
 WHERE CONTACT_PHONE_NUMBER IS NULL OR TRIM(CONTACT_PHONE_NUMBER) = '';

SELECT 'HOST_BANK contact details present' AS result;
