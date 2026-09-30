-- ============================================================================
-- PAYMENT_ENRICHED_FIELDS — labels for OUTCLRDDA (collection code 03) enriched slots
-- Run against: primary database (mcb_check_payment_platform)
-- Spec: SPEC_workflow_master_OUTCLRDDA_CDE.md §6.2
--
-- Describes the return item's own ENRICHED_DATA_NN slots for UI/reporting.
-- Matches what the OUTCLRDDA CDE_JSON_Rule writes:
--   ENRICHED_DATA_01 = parent On-Us Positive Pay Flag
--   ENRICHED_DATA_02 = parent BOFD RT
-- Unique key (COLLECTION_CODE, ENRICHED_COLUMN_LABEL) -> idempotent upsert.
-- ============================================================================

INSERT INTO PAYMENT_ENRICHED_FIELDS (COLLECTION_CODE, ENRICHED_COLUMN_LABEL, ENRICHED_COLUMN_VALUE) VALUES
  ('03', 'ENRICHED_DATA_01', 'Parent On-Us Positive Pay Flag'),
  ('03', 'ENRICHED_DATA_02', 'Parent BOFD RT')
ON DUPLICATE KEY UPDATE ENRICHED_COLUMN_VALUE = VALUES(ENRICHED_COLUMN_VALUE);
