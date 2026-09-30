-- ============================================================================
-- WORKFLOW_MASTER — IQV JSON Rule for OUTCLRDDA (all checks OFF = bypass)
-- Run against: business_rules database. UPDATE only; OUTCLRDDA row must exist
-- (created by 10_seed_workflow_outclrdda.sql). INCLFF / OUTCLRBR untouched.
-- Spec: SPEC_workflow_master_OUTCLRDDA_IQV.md
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

UPDATE WORKFLOW_MASTER SET
  IQV_JSON_Rule = '{
    "collectionCodeMap": {
      "OUTCLRDDA": {
        "tiffValidation": false,
        "iqa": false,
        "iua": false,
        "fraud": false,
        "iuaOcr": false
      }
    }
  }'
WHERE Collection_Code = 'OUTCLRDDA';
