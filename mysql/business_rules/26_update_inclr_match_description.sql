-- ============================================================================
-- SPEC_09 Phase 3/4: INCLRF / INCLRB return-match rule - description text only.
-- Run against: business_rules database.
--
-- The deposit match is now done by Data Services against ITEM_DETAILS deposit rows
-- (natural key / DEPOSIT_KEY), no longer via TAE_TRANSACTION -> TAE_DEPOSIT. The
-- api_lookup step itself is unchanged; only its human-readable `description` string
-- inside CDE_JSON_Rule still names the old tables. This script fixes that text on
-- databases that already carry the v0.9.2 seed (business_rules/19 is left exactly as
-- released, because it is already deployed).
--
-- Plain text-for-text replacement, so the JSON stays valid. Idempotent: a second run
-- finds nothing to replace. Only INCLRF / INCLRB are touched.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};
UPDATE WORKFLOW_MASTER
   SET CDE_JSON_Rule = REPLACE(CAST(CDE_JSON_Rule AS CHAR),
         'Match the return to the original deposit via TAE_TRANSACTION -> TAE_DEPOSIT; return confidence + depositor account',
         'Match the return to the original deposit by natural key against ITEM_DETAILS deposit rows; return confidence + depositor account')
 WHERE Collection_Code IN ('INCLRF', 'INCLRB')
   AND CDE_JSON_Rule IS NOT NULL
   AND LOCATE('via TAE_TRANSACTION -> TAE_DEPOSIT', CAST(CDE_JSON_Rule AS CHAR)) > 0;
