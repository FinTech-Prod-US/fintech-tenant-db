-- ============================================================================
-- SPEC_09 Phase 4: ITEM_DETAILS_ENRICHED.REPAIRED_MICR_ACCOUNT / REPAIRED_MICR_RT (idempotent).
-- Run against: ${DB_NAME_PRIMARY}. Re-running changes nothing.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='ITEM_DETAILS_ENRICHED' AND COLUMN_NAME='REPAIRED_MICR_ACCOUNT');
SET @s := IF(@c=0,
 'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN REPAIRED_MICR_ACCOUNT VARCHAR(34) NULL COMMENT ''Account from an ACCEPTED payment-repair correction; ORIG_MICR_ACCOUNT stays immutable''',
 'SELECT ''ITEM_DETAILS_ENRICHED.REPAIRED_MICR_ACCOUNT exists'' AS result');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='ITEM_DETAILS_ENRICHED' AND COLUMN_NAME='REPAIRED_MICR_RT');
SET @s := IF(@c=0,
 'ALTER TABLE ITEM_DETAILS_ENRICHED ADD COLUMN REPAIRED_MICR_RT CHAR(9) NULL COMMENT ''RT from an ACCEPTED payment-repair correction''',
 'SELECT ''ITEM_DETAILS_ENRICHED.REPAIRED_MICR_RT exists'' AS result');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- One-time backfill that reproduces exactly what the retired Phase 1 Posting parse applied: the item's linked
-- ADJUSTMENT_ID, ROUTING_DECISION = 'SEND_TO_DQV_THEN_BR' only. HOLD_FOR_APPROVAL rows are never copied, whatever
-- their APPROVAL_STATUS, so the backfill cannot introduce an approval bypass. CASE guards JSON_VALID because MySQL
-- does not guarantee WHERE evaluation order.
UPDATE ITEM_DETAILS_ENRICHED ide
  JOIN ADE_CORRECTION_LOG acl ON acl.ADJUSTMENT_ID = ide.ADJUSTMENT_ID
   SET ide.REPAIRED_MICR_ACCOUNT = NULLIF(TRIM(JSON_UNQUOTE(JSON_EXTRACT(acl.CORRECTED_FIELDS_JSON,'$.ORIG_MICR_ACCOUNT'))),''),
       ide.REPAIRED_MICR_RT      = NULLIF(TRIM(JSON_UNQUOTE(JSON_EXTRACT(acl.CORRECTED_FIELDS_JSON,'$.ORIG_MICR_RT'))),'')
 WHERE ide.REPAIRED_MICR_ACCOUNT IS NULL AND ide.REPAIRED_MICR_RT IS NULL
   AND acl.ROUTING_DECISION = 'SEND_TO_DQV_THEN_BR'
   AND CASE WHEN JSON_VALID(acl.CORRECTED_FIELDS_JSON)
            THEN JSON_CONTAINS_PATH(acl.CORRECTED_FIELDS_JSON,'one','$.ORIG_MICR_ACCOUNT','$.ORIG_MICR_RT')
            ELSE 0 END = 1;
SELECT 'item details enriched repaired micr applied' AS result;
