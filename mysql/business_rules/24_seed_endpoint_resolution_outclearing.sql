-- ============================================================================
-- Endpoint Resolution seed: outclearing channels (OUTCLFBR/ATM/MOB/RDC/LBX/COR)
-- Run against: business_rules database.
--
-- Before this script ENDPOINT_RESOLUTION_RULES had rows only for INCLFF, INCLFB,
-- INCLRF, INCLRB and OUTCLRDDA. Outclearing items therefore matched no rule, the
-- BR Engine fell back to WORKFLOW_MASTER.CDE_Endpoint_Resolution_Rule, found
-- nothing and flagged every item ENDPOINT_REVIEW, so no cash letter was built.
--
-- Per code, two rows:
--   FORWARD (priority 100): Federal Reserve 021000089 / FED. Approved checks.
--   RETURN  (priority 200): default return 088888888 / FED (same default as
--                           INCLFF rule 10). Ops-rejected / exception items.
-- ENDPOINT_DIRECTION_RULES already maps these codes to FORWARD by default and
-- ops rejects force RETURN, so only the resolution rows are missing.
--
-- BUSINESS DECISION PENDING: 088888888 is a placeholder return endpoint. Replace
-- with the owner's real value (or per-payor-RT rows / ENDPOINT_ROUTE_REF lookup)
-- by UPDATE of these rows; the script will not overwrite edited rows on rerun.
--
-- Idempotent: INSERT ... WHERE NOT EXISTS on (COLLECTION_CODE, DIRECTION,
-- RT_PATTERN IS NULL). The table has no business unique key.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

INSERT INTO ENDPOINT_RESOLUTION_RULES
  (COLLECTION_CODE, DIRECTION, RT_PATTERN, PRIORITY, ENDPOINT_RT, ENDPOINT_NETWORK,
   CDE_ENDPOINT_RESOLUTION_RULE, ACTIVE, DESCRIPTION)
SELECT c.CODE, 'FORWARD', NULL, 100, '021000089', 'FED',
       '{"steps": [{"id": "lookup_endpoint", "sql": "SELECT ENDPOINT_RT, ENDPOINT_NETWORK FROM ENDPOINT_RESOLUTION_RULES WHERE COLLECTION_CODE = :cc AND DIRECTION = :dir AND (RT_PATTERN IS NULL OR RT_PATTERN = :rt) AND ACTIVE = 1 ORDER BY PRIORITY ASC LIMIT 1", "type": "sql_lookup", "table": "ENDPOINT_RESOLUTION_RULES", "params": {"cc": "$ctx.currentItem.CollectionCode", "rt": "$ctx.currentItem.RT", "dir": "$ctx.currentItem.Direction"}, "onNoMatch": {"set": {"flagForReview": true}}, "outputMapping": {"endpointRt": "ENDPOINT_RT", "endpointNetwork": "ENDPOINT_NETWORK"}}]}',
       1, CONCAT(c.CODE, ': forward to Federal Reserve (default)')
FROM (SELECT 'OUTCLFBR' AS CODE UNION ALL SELECT 'OUTCLFATM' UNION ALL SELECT 'OUTCLFMOB'
      UNION ALL SELECT 'OUTCLFRDC' UNION ALL SELECT 'OUTCLFLBX' UNION ALL SELECT 'OUTCLFCOR') c
WHERE NOT EXISTS (SELECT 1 FROM ENDPOINT_RESOLUTION_RULES r
                  WHERE r.COLLECTION_CODE = c.CODE AND r.DIRECTION = 'FORWARD' AND r.RT_PATTERN IS NULL);

INSERT INTO ENDPOINT_RESOLUTION_RULES
  (COLLECTION_CODE, DIRECTION, RT_PATTERN, PRIORITY, ENDPOINT_RT, ENDPOINT_NETWORK,
   CDE_ENDPOINT_RESOLUTION_RULE, ACTIVE, DESCRIPTION)
SELECT c.CODE, 'RETURN', NULL, 200, '088888888', 'FED',
       '{"steps": [{"id": "default_return", "set": {"endpointRt": "088888888", "endpointNetwork": "FED"}, "type": "set"}]}',
       1, CONCAT(c.CODE, ': default return endpoint (placeholder, owner to confirm)')
FROM (SELECT 'OUTCLFBR' AS CODE UNION ALL SELECT 'OUTCLFATM' UNION ALL SELECT 'OUTCLFMOB'
      UNION ALL SELECT 'OUTCLFRDC' UNION ALL SELECT 'OUTCLFLBX' UNION ALL SELECT 'OUTCLFCOR') c
WHERE NOT EXISTS (SELECT 1 FROM ENDPOINT_RESOLUTION_RULES r
                  WHERE r.COLLECTION_CODE = c.CODE AND r.DIRECTION = 'RETURN' AND r.RT_PATTERN IS NULL);
