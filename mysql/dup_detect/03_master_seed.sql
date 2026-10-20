-- ============================================================================
-- dup_detect MASTER/REFERENCE tables only (no transactional data)
-- Used by seed_tenant.py for clean tenant seeding
-- Run against: dup_detect database
-- ============================================================================

USE ${DB_NAME_DUP_DETECT};

-- Seed: WORKFLOW_MASTER (1 row) - Duplicate detection configuration
INSERT IGNORE INTO WORKFLOW_MASTER (Id, Collection_Code, Name, FDE_JSON, DUP_JSON) VALUES
(1, 'INCLFB', 'Forward clearing BOFA', NULL, '{"namespace": {"schema": "DUP_PAYMENT_CHECK", "binTable": "WORK_ITEM_CHECK_BIN", "errorQueue": "DUPLICATEDETECT.ERROR.QUEUE", "inputQueue": "DUPLICATEDETECT.INPUT.QUEUE", "reviewFlag": true, "outputQueue": "DUPLICATEDETECT.OUTPUT.QUEUE", "detailsTable": "WORK_ITEM_CHECK_DETAILS", "errorDefault": "", "errorCategory": "", "duplicateTable": "WORK_ITEM_CHECK_DUPLICATE", "Collection code": "INCLF", "expiryCriterias": [{"expiry": "90 days"}], "excludeCriterias": [{"condition": {"value": "15", "colName": "AMOUNT", "operator": "LTE"}}, {"condition": [{"value": "5555-22??", "colName": "ROUTING_TRANSIT", "operator": "EQ"}, {"value": "999999", "colName": "ACCOUNT", "operator": "EQ"}]}], "matchingCriterias": [{"condition": [{"colName": "ACCOUNT = {}", "operator": "AND"}, {"colName": "AMOUNT = {}", "operator": "AND"}, {"colName": "RT = {}", "operator": "OR"}, {"colName": "CHECK_NO = {}", "operator": "OR"}, {"colName": "AUX_ON_US = {}"}]}]}}')
ON DUPLICATE KEY UPDATE DUP_JSON = VALUES(DUP_JSON);
