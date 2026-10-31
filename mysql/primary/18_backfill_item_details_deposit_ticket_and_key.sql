-- ============================================================================
-- SPEC_09 Phase 3: backfill historical DEPOSIT_TICKET + DEPOSIT_KEY (idempotent).
-- Mirrors the DI algorithm (data-ingestion depositCredit.service.js). Run after 17.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

-- (a) historical deposit tickets (real credit sentinel on an outclearing-forward cash letter)
UPDATE ITEM_DETAILS id
  JOIN CASH_LETTER_DETAILS cld ON cld.CASHLTR_ID = id.CASHLETTER_ID
   SET id.CREDIT_ITEM_TYPE = 'DEPOSIT_TICKET'
 WHERE id.CREDIT_ITEM_TYPE IS NULL
   AND COALESCE(id.SYNTHESIZED_CREDIT,0) = 0
   AND UPPER(id.ORIG_MICR_AUXONUS) = 'CREDIT'
   AND cld.COLLECTION_CODE LIKE 'OUTCLF%';

-- (b) DEPOSIT_KEY for every item of a bundle that holds a DEPOSIT_TICKET.
-- Run number = count of credit rows with the same (bundle, seq prefix) up to and including this row,
-- ordered by PAYMENT_ID. This is exactly the DI run algorithm (section 5.2).
WITH base AS (
  SELECT id.PAYMENT_ID, id.FILE_ID, id.BUNDLE_ID,
         TRIM(cld.CASH_LETTER_ID) AS X9_CL, TRIM(b.ORIG_BUNDLE_ID) AS X9_BUNDLE,
         CASE WHEN JSON_VALID(r.RECORD_DATA) THEN JSON_UNQUOTE(JSON_EXTRACT(r.RECORD_DATA,'$.eceInstitutionItemSequenceNumber')) END AS SEQ15,
         (id.CREDIT_ITEM_TYPE = 'DEPOSIT_TICKET') AS IS_CREDIT
    FROM ITEM_DETAILS id
    JOIN CASH_LETTER_DETAILS cld ON cld.CASHLTR_ID = id.CASHLETTER_ID
    JOIN BUNDLE_DETAILS b        ON b.BUNDLE_ID    = id.BUNDLE_ID
    JOIN ITEM_DETAILS_REC r      ON r.PAYMENT_ID   = id.PAYMENT_ID AND r.RECORD_TYPE = 25
   WHERE cld.COLLECTION_CODE LIKE 'OUTCLF%'
     AND id.BUNDLE_ID IN (SELECT BUNDLE_ID FROM ITEM_DETAILS WHERE CREDIT_ITEM_TYPE = 'DEPOSIT_TICKET')
),
runs AS (
  SELECT base.*, LEFT(SEQ15,7) AS PFX,
         SUM(IS_CREDIT) OVER (PARTITION BY BUNDLE_ID, LEFT(SEQ15,7)
                              ORDER BY PAYMENT_ID ROWS UNBOUNDED PRECEDING) AS RUN_NO
    FROM base WHERE SEQ15 REGEXP '^[0-9]{15}$'
)
UPDATE ITEM_DETAILS id JOIN runs ON runs.PAYMENT_ID = id.PAYMENT_ID
   SET id.DEPOSIT_KEY = CONCAT('F', runs.FILE_ID, '-C', runs.X9_CL, '-B', runs.X9_BUNDLE, '-D', runs.PFX,
                               IF(GREATEST(runs.RUN_NO,1) > 1, CONCAT('-', GREATEST(runs.RUN_NO,1)), ''))
 WHERE id.DEPOSIT_KEY IS NULL;
