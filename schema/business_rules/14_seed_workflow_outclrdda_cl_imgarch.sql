-- ============================================================================
-- WORKFLOW_MASTER — CashLetter + Image Archive rules for OUTCLRDDA
-- Copied verbatim from INCLFF (universal aggregation/archive rule).
-- Run against: business_rules database. UPDATE only; OUTCLRDDA row must exist.
-- Spec: SPEC_workflow_master_OUTCLRDDA_CL_IMGARCH_DUP.md
--
-- Uses a self-JOIN from the INCLFF row so the values are byte-identical and
-- self-heal if INCLFF's universal rule changes.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

UPDATE WORKFLOW_MASTER t
  JOIN WORKFLOW_MASTER s ON s.Collection_Code = 'INCLFF'
   SET t.CL_JSON_Rule = s.CL_JSON_Rule,
       t.ImageArchive_JSON_Rule = s.ImageArchive_JSON_Rule
 WHERE t.Collection_Code = 'OUTCLRDDA';
