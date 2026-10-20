-- ============================================================================
-- PAYMENT_ENRICHED_FIELDS — labels for INCLRF/INCLRB (collection code 02) slots
-- Run against: primary database (mcb_check_payment_platform)
-- Spec: SPEC_10_returned_deposited_item_pipeline.md (Phase A, §4.5)
--
-- Describes the returned-deposited-item's own ENRICHED_DATA_NN slots for
-- UI/reporting. Matches what the INCLRF/INCLRB CDE_JSON_Rule writes:
--   ENRICHED_DATA_01 = deposit match confidence (SINGLE / NONE / MULTIPLE)
--   ENRICHED_DATA_02 = matched depositor account (debit target)
--   ENRICHED_DATA_03 = matched deposit id
-- Collection type 02 covers both INCLRF (Fed) and INCLRB (bank via SVPCO).
-- Unique key (COLLECTION_CODE, ENRICHED_COLUMN_LABEL) -> idempotent upsert.
-- ============================================================================

INSERT INTO PAYMENT_ENRICHED_FIELDS (COLLECTION_CODE, ENRICHED_COLUMN_LABEL, ENRICHED_COLUMN_VALUE) VALUES
  ('02', 'ENRICHED_DATA_01', 'Deposit Match Confidence'),
  ('02', 'ENRICHED_DATA_02', 'Matched Depositor Account'),
  ('02', 'ENRICHED_DATA_03', 'Matched Deposit ID')
ON DUPLICATE KEY UPDATE ENRICHED_COLUMN_VALUE = VALUES(ENRICHED_COLUMN_VALUE);
