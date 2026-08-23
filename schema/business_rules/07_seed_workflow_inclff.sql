-- ============================================================================
-- WORKFLOW_MASTER — Copy JSON Rules from INCFF/INCFB to INCLFF/INCLFB
-- The INCFF/INCFB rows have the correct JSON rules. INCLFF/INCLFB are the
-- collection codes used by the pipeline but were created without rules.
-- This script ensures INCLFF and INCLFB have the same rules as their
-- INCFF/INCFB counterparts.
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

-- Copy all JSON rules from INCFF → INCLFF
UPDATE WORKFLOW_MASTER
SET FDE_JSON_Rule = (SELECT FDE_JSON_Rule FROM (SELECT FDE_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    CDE_JSON_Rule = (SELECT CDE_JSON_Rule FROM (SELECT CDE_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    IQV_JSON_Rule = (SELECT IQV_JSON_Rule FROM (SELECT IQV_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    DQV_JSON_Rule = (SELECT DQV_JSON_Rule FROM (SELECT DQV_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    CL_JSON_Rule = (SELECT CL_JSON_Rule FROM (SELECT CL_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    ImageArchive_JSON_Rule = (SELECT ImageArchive_JSON_Rule FROM (SELECT ImageArchive_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t),
    CDE_Endpoint_Resolution_Rule = (SELECT CDE_Endpoint_Resolution_Rule FROM (SELECT CDE_Endpoint_Resolution_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFF') t)
WHERE Collection_Code = 'INCLFF'
  AND CDE_JSON_Rule IS NULL;

-- Copy all JSON rules from INCFB → INCLFB
UPDATE WORKFLOW_MASTER
SET FDE_JSON_Rule = (SELECT FDE_JSON_Rule FROM (SELECT FDE_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    CDE_JSON_Rule = (SELECT CDE_JSON_Rule FROM (SELECT CDE_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    IQV_JSON_Rule = (SELECT IQV_JSON_Rule FROM (SELECT IQV_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    DQV_JSON_Rule = (SELECT DQV_JSON_Rule FROM (SELECT DQV_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    CL_JSON_Rule = (SELECT CL_JSON_Rule FROM (SELECT CL_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    ImageArchive_JSON_Rule = (SELECT ImageArchive_JSON_Rule FROM (SELECT ImageArchive_JSON_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t),
    CDE_Endpoint_Resolution_Rule = (SELECT CDE_Endpoint_Resolution_Rule FROM (SELECT CDE_Endpoint_Resolution_Rule FROM WORKFLOW_MASTER WHERE Collection_Code = 'INCFB') t)
WHERE Collection_Code = 'INCLFB'
  AND CDE_JSON_Rule IS NULL;
