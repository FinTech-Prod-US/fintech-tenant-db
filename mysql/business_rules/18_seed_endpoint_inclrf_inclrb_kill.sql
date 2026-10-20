-- ============================================================================
-- Endpoint Resolution — INCLRF / INCLRB (returned deposited items): terminal KILL
-- Run against: business_rules database.
-- Spec: SPEC_10_returned_deposited_item_pipeline.md (Phase A, §4.3)
--
-- INCLRF (exception-in from Fed) and INCLRB (exception-in from bank via SVPCO) are
-- returns of checks OUR customer deposited and we sent out for clearing. They are
-- TERMINAL at ACCS: we debit our depositor and do NOT forward them anywhere. So
-- every matched item must resolve to KILL regardless of its payor RT.
--
-- These codes previously shipped with DIRECTION=FORWARD rows (transit assumption).
-- This migration flips them to RETURN and adds an unconditional-KILL resolution
-- rule. INCLFF/INCLFB forward and OUTCL* flows are untouched.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

-- Ensure the KILL sentinel exists (idempotent; also created by the OUTCLRDDA seed).
ALTER TABLE ENDPOINT_ROUTE_REF
  MODIFY EndpointNetwork ENUM('FED','SVPCO','KILL') NOT NULL;

INSERT INTO ENDPOINT_ROUTE_REF (RT, EndpointRT, EndpointNetwork, Status)
VALUES ('999999999', '999999999', 'KILL', 'ACTIVE')
ON DUPLICATE KEY UPDATE EndpointRT = '999999999', EndpointNetwork = 'KILL', Status = 'ACTIVE';

-- (1) DIRECTION: flip INCLRF/INCLRB from FORWARD (transit) to RETURN (terminal).
-- Table PK is RULE_ID (no business unique key), so clear existing rows then insert
-- a single catch-all per code.
DELETE FROM ENDPOINT_DIRECTION_RULES WHERE COLLECTION_CODE IN ('INCLRF', 'INCLRB');

-- EXCEPTION_PATTERN='*' (catch-all), NOT NULL: returned deposited items are ALWAYS
-- carried as an exception (exceptionCode=RETURNED_DEPOSIT from the CDE match rule),
-- so a NULL (no-exception) pattern would never match and the direction lookup would
-- fall through to its FORWARD default. '*' matches regardless of exception code,
-- which is correct here because these flows are unconditionally terminal returns.
INSERT INTO ENDPOINT_DIRECTION_RULES
  (COLLECTION_CODE, EXCEPTION_PATTERN, DIRECTION, PRIORITY, DESCRIPTION, ACTIVE)
VALUES
  ('INCLRF', '*', 'RETURN', 100, 'INCLRF: returned deposited item (Fed) is terminal -> RETURN/KILL', 1),
  ('INCLRB', '*', 'RETURN', 100, 'INCLRB: returned deposited item (bank via SVPCO) is terminal -> RETURN/KILL', 1);

-- (2) RESOLUTION: unconditional KILL for INCLRF/INCLRB RETURN items. Unlike
-- OUTCLRDDA (which routes by BOFD RT to FED/SVPCO/KILL), these always terminate,
-- so the rule sets killed=true directly without an RT lookup.
DELETE FROM ENDPOINT_RESOLUTION_RULES WHERE COLLECTION_CODE IN ('INCLRF', 'INCLRB');

INSERT INTO ENDPOINT_RESOLUTION_RULES
  (COLLECTION_CODE, DIRECTION, RT_PATTERN, REJECTION_REASON, PRIORITY,
   ENDPOINT_RT, ENDPOINT_NETWORK, CDE_ENDPOINT_RESOLUTION_RULE, ACTIVE, DESCRIPTION)
-- ENDPOINT_RT / ENDPOINT_NETWORK are NOT NULL row-level placeholders; the JSON rule
-- below computes the resolution (sets killed + endpointNetwork=KILL).
VALUES
  ('INCLRF', 'RETURN', NULL, NULL, 100,
   '999999999', 'KILL', '{
     "steps": [
       {
         "id": "terminal_kill",
         "type": "set",
         "set": { "killed": true, "endpointRt": "999999999", "endpointNetwork": "KILL", "resolvedBy": "INCLRF_TERMINAL" }
       }
     ]
   }', 1,
   'INCLRF returned deposited item: terminal KILL (debit depositor, no external send)'),
  ('INCLRB', 'RETURN', NULL, NULL, 100,
   '999999999', 'KILL', '{
     "steps": [
       {
         "id": "terminal_kill",
         "type": "set",
         "set": { "killed": true, "endpointRt": "999999999", "endpointNetwork": "KILL", "resolvedBy": "INCLRB_TERMINAL" }
       }
     ]
   }', 1,
   'INCLRB returned deposited item: terminal KILL (debit depositor, no external send)');
