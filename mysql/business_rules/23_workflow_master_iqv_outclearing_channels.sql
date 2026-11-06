-- ============================================================================
-- WORKFLOW_MASTER: IQV validation flags for every outclearing channel (idempotent). Run after 22.
-- Run against: business_rules database
--
-- Why: IQV reads its validation flags from IQV_JSON_Rule.collectionCodeMap[<item collection code>]. When the code is
-- missing from the map, or the collection code has no WORKFLOW_MASTER row, IQV falls back to "run ALL validations"
-- (IQA + IUA with Tesseract OCR on 8 zones + fraud), about 30 s per image. CDE gives up after its HTTP timeout, so every
-- check of an outclearing file ended PROCESSING_FAILED ("Timeout on blocking read ..."), while inclearing, which has
-- correct flags, was fast. Measured on one TAE simulator image: wrong key 103.5 s, correct key 0.9 s.
--
-- What this script does:
--   1. Repairs OUTCLFBR where the map key is the typo INCFF (found on a live local DB; the 09 seed script is correct).
--   2. Adds a WORKFLOW_MASTER row, with ONLY the IQV rule, for OUTCLFATM, OUTCLFMOB, OUTCLFRDC and OUTCLFLBX.
--      Data-services reads one rule column at a time and returns null for both a missing row and a NULL column, so a row
--      holding only IQV_JSON_Rule changes IQV behaviour and nothing else.
--   3. Fills IQV_JSON_Rule on those rows if the row already exists with a NULL IQV rule. An existing IQV rule is never changed.
-- Flags match OUTCLFBR / INCLFF: IQA + TIFF validation on, IUA / IUA-OCR / fraud off.
--
-- Not covered here (decide separately): OUTCLFCOR (correspondent) has no row either, and INCLFB items have no matching row
-- (the row is spelled INCFB). Both still fall back to run-all.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

-- 1. Repair the OUTCLFBR typo key (no-op when the key is already OUTCLFBR)
UPDATE WORKFLOW_MASTER
SET IQV_JSON_Rule = JSON_OBJECT('collectionCodeMap',
      JSON_OBJECT('OUTCLFBR', JSON_EXTRACT(IQV_JSON_Rule, '$.collectionCodeMap.INCFF')))
WHERE Collection_Code = 'OUTCLFBR'
  AND JSON_CONTAINS_PATH(IQV_JSON_Rule, 'one', '$.collectionCodeMap.INCFF')
  AND NOT JSON_CONTAINS_PATH(IQV_JSON_Rule, 'one', '$.collectionCodeMap.OUTCLFBR');

-- 2. IQV-only rows for the other outclearing channels (Collection_Code is UNIQUE, so INSERT IGNORE is idempotent)
INSERT IGNORE INTO WORKFLOW_MASTER (Collection_Code, Name, IQV_JSON_Rule) VALUES
('OUTCLFATM', 'Outclearing ATM - IQV validation flags',
 '{"collectionCodeMap": {"OUTCLFATM": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'),
('OUTCLFMOB', 'Outclearing Mobile - IQV validation flags',
 '{"collectionCodeMap": {"OUTCLFMOB": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'),
('OUTCLFRDC', 'Outclearing Remote Deposit - IQV validation flags',
 '{"collectionCodeMap": {"OUTCLFRDC": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'),
('OUTCLFLBX', 'Outclearing Lockbox - IQV validation flags',
 '{"collectionCodeMap": {"OUTCLFLBX": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}');

-- 3. A pre-existing row with no IQV rule gets the flags; an existing IQV rule is left alone
UPDATE WORKFLOW_MASTER SET IQV_JSON_Rule = '{"collectionCodeMap": {"OUTCLFATM": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'
  WHERE Collection_Code = 'OUTCLFATM' AND IQV_JSON_Rule IS NULL;
UPDATE WORKFLOW_MASTER SET IQV_JSON_Rule = '{"collectionCodeMap": {"OUTCLFMOB": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'
  WHERE Collection_Code = 'OUTCLFMOB' AND IQV_JSON_Rule IS NULL;
UPDATE WORKFLOW_MASTER SET IQV_JSON_Rule = '{"collectionCodeMap": {"OUTCLFRDC": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'
  WHERE Collection_Code = 'OUTCLFRDC' AND IQV_JSON_Rule IS NULL;
UPDATE WORKFLOW_MASTER SET IQV_JSON_Rule = '{"collectionCodeMap": {"OUTCLFLBX": {"iqa": true, "iua": false, "fraud": false, "iuaOcr": false, "tiffValidation": true}}}'
  WHERE Collection_Code = 'OUTCLFLBX' AND IQV_JSON_Rule IS NULL;

SELECT 'workflow master iqv outclearing channels applied' AS result;
