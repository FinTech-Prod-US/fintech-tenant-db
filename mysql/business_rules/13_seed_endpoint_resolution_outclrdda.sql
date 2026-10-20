-- ============================================================================
-- Endpoint Resolution — OUTCLRDDA (outgoing returns), route by BOFD RT
-- Run against: business_rules database. Additive; INCLFF/INCLRF/OUTCL* untouched.
-- Spec: SPEC_endpoint_resolution_OUTCLRDDA.md
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

-- (1) Extend ENDPOINT_ROUTE_REF to represent KILL, and activate the 999999999 sentinel.
ALTER TABLE ENDPOINT_ROUTE_REF
  MODIFY EndpointNetwork ENUM('FED','SVPCO','KILL') NOT NULL;

INSERT INTO ENDPOINT_ROUTE_REF (RT, EndpointRT, EndpointNetwork, Status)
VALUES ('999999999', '999999999', 'KILL', 'ACTIVE')
ON DUPLICATE KEY UPDATE EndpointRT = '999999999', EndpointNetwork = 'KILL', Status = 'ACTIVE';

-- (2) DIRECTION: force OUTCLRDDA items to RETURN (GAP 1). Endpoint resolution derives
-- direction from ENDPOINT_DIRECTION_RULES; OUTCLRDDA shipped with FORWARD rows that
-- must be removed so returns resolve as RETURN. Table has no unique business key
-- (PK is RULE_ID), so clear existing OUTCLRDDA rows first, then insert one catch-all.
DELETE FROM ENDPOINT_DIRECTION_RULES WHERE COLLECTION_CODE = 'OUTCLRDDA';

INSERT INTO ENDPOINT_DIRECTION_RULES
  (COLLECTION_CODE, EXCEPTION_PATTERN, DIRECTION, PRIORITY, DESCRIPTION, ACTIVE)
VALUES
  ('OUTCLRDDA', NULL, 'RETURN', 100, 'OUTCLRDDA: outgoing returns always RETURN', 1);

-- (3) OUTCLRDDA RETURN catch-all endpoint rule (routes by BOFD RT via ENDPOINT_ROUTE_REF)
-- PK is RULE_ID (no business unique key), so clear existing OUTCLRDDA rules first for idempotency.
DELETE FROM ENDPOINT_RESOLUTION_RULES WHERE COLLECTION_CODE = 'OUTCLRDDA';

INSERT INTO ENDPOINT_RESOLUTION_RULES
  (COLLECTION_CODE, DIRECTION, RT_PATTERN, REJECTION_REASON, PRIORITY,
   ENDPOINT_RT, ENDPOINT_NETWORK, CDE_ENDPOINT_RESOLUTION_RULE, ACTIVE, DESCRIPTION)
-- ENDPOINT_RT / ENDPOINT_NETWORK columns are NOT NULL; they act as row-level
-- placeholders/fallbacks. The actual endpoint is computed by the JSON rule below
-- (writes ctx.vars.endpointRt/endpointNetwork), so these placeholders are never the
-- resolved value for a matched item.
VALUES
  ('OUTCLRDDA', 'RETURN', NULL, NULL, 200,
   '000000000', 'FED', '{
     "steps": [
       {
         "id": "classify_bofd_rt",
         "type": "sql_lookup",
         "table": "ENDPOINT_ROUTE_REF",
         "sql": "SELECT EndpointRT, EndpointNetwork FROM ENDPOINT_ROUTE_REF WHERE RT = :rt AND Status = ''ACTIVE''",
         "params": { "rt": "$ctx.currentItem.RT" },
         "outputMapping": { "endpointRt": "EndpointRT", "endpointNetwork": "EndpointNetwork" },
         "onMatch": "continue",
         "onNoMatch": { "goto": "flag_for_review" }
       },
       {
         "id": "kill_gate",
         "type": "condition",
         "condition": "$vars.endpointNetwork == ''KILL''",
         "onTrue": { "set": { "killed": true, "endpointRt": null, "endpointNetwork": "KILL" } },
         "onFalse": "continue"
       },
       { "id": "done", "type": "set", "set": { "resolvedBy": "ENDPOINT_ROUTE_REF" } },
       { "id": "flag_for_review", "type": "set", "set": { "flagForReview": true } }
     ]
   }', 1,
   'OUTCLRDDA return: route by BOFD RT via ENDPOINT_ROUTE_REF to FED/SVPCO/KILL, else flag for review');
