-- ============================================================================
-- WORKFLOW_MASTER — CashLetter Close Rules for all Collection Codes
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

-- Inclearing Forward (Fed & Bank)
INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('INCLFF', 'Inclearing Forward Fed', '{"maxItemCount": 500, "maxAmount": 10000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('INCLFB', 'Inclearing Forward Bank', '{"maxItemCount": 500, "maxAmount": 10000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

-- Inclearing Return (Fed & Bank)
INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('INCLRF', 'Inclearing Return Fed', '{"maxItemCount": 300, "maxAmount": 5000000.0, "timeCutoffMinutes": 360, "idleTimeoutMinutes": 20}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('INCLRB', 'Inclearing Return Bank', '{"maxItemCount": 300, "maxAmount": 5000000.0, "timeCutoffMinutes": 360, "idleTimeoutMinutes": 20}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

-- Outclearing POD (TAE channels)
INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFBR', 'POD Branch Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFATM', 'POD ATM Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFMOB', 'POD Mobile Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFRDC', 'POD RDC Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFLBX', 'POD Lockbox Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLFCOR', 'POD Correspondent Forward', '{"maxItemCount": 1000, "maxAmount": 20000000.0, "timeCutoffMinutes": 480, "idleTimeoutMinutes": 30}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

-- Outclearing Return (EIE sources)
INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLRDDA', 'Outgoing Return DDA', '{"maxItemCount": 500, "maxAmount": 10000000.0, "timeCutoffMinutes": 360, "idleTimeoutMinutes": 20}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLRCD', 'Outgoing Return Card', '{"maxItemCount": 500, "maxAmount": 10000000.0, "timeCutoffMinutes": 360, "idleTimeoutMinutes": 20}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, CL_JSON_Rule)
VALUES ('OUTCLRLN', 'Outgoing Return Loan', '{"maxItemCount": 500, "maxAmount": 10000000.0, "timeCutoffMinutes": 360, "idleTimeoutMinutes": 20}')
ON DUPLICATE KEY UPDATE CL_JSON_Rule = VALUES(CL_JSON_Rule);
