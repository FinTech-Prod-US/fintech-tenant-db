-- ============================================================================
-- WORKFLOW_MASTER — CDE JSON Rule for INCLRF / INCLRB (returned deposited item)
-- Run against: business_rules database. UPDATE only; INCLRF/INCLRB rows must exist.
-- Spec: SPEC_10_returned_deposited_item_pipeline.md (Phase A, §4.2)
--
-- One api_lookup to Data Services /items/match-returned-deposit matches the return
-- {RT, account, serial, amount} to the ORIGINAL deposit (TAE_TRANSACTION ->
-- TAE_DEPOSIT) and returns a match confidence + the depositor account. Exactly one
-- match -> exceptionCode=RETURNED_DEPOSIT (CDE dispositions RETURN -> terminal KILL,
-- posting debits the depositor). Zero or multiple matches -> ENDPOINT_REVIEW
-- (operator selects the deposit account; same KILL + debit-back path afterwards).
--
-- Enriched_Data_01 = match confidence, 02 = matched depositor account, 03 = deposit id.
-- (SQL single quotes inside the JSON are doubled: '' -> '''' for empty-string tests.)
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

UPDATE WORKFLOW_MASTER SET
  CDE_JSON_Rule = '{
    "workflow": {
      "name": "x9-item-enrichment-returned-deposited-item-v1",
      "scope": "perItem",
      "description": "Returned deposited item (INCLRF/INCLRB): match return to original deposit, resolve depositor account; single match -> debit-back/KILL, else operator review",
      "settings": { "timeout_ms": 5000, "stop_on_error": true },
      "steps": [
        {
          "id": "init_item_context",
          "type": "transform",
          "on_success": { "save_as": {
            "$ctx.currentItem.exceptionCode": null,
            "$ctx.currentItem.enrichmentStatus": "IN_PROGRESS",
            "$ctx.currentItem.exceptionDetails": null
          }},
          "description": "Initialize item enrichment output fields"
        },
        {
          "id": "match_returned_deposit",
          "type": "api_lookup",
          "method": "GET",
          "url": "http://accs-mcb-data-services:8084/api/v1/items/match-returned-deposit?rt=:rt&account=:account&serial=:serial&amount=:amount",
          "params": {
            "rt": "$ctx.currentItem.RT",
            "account": "$ctx.currentItem.AccountNumber",
            "serial": "$ctx.currentItem.CheckSerialNumber",
            "amount": "$ctx.currentItem.Amount"
          },
          "on_success": { "save_as": {
            "$ctx.currentItem.Enriched_Data_01": "$response.confidence",
            "$ctx.currentItem.Enriched_Data_02": "$response.depositAccount",
            "$ctx.currentItem.Enriched_Data_03": "$response.depositId",
            "$ctx.vars.confidence": "$response.confidence",
            "$ctx.vars.depositAccount": "$response.depositAccount"
          }},
          "on_error": { "goto": "end_with_match_error" },
          "description": "Match the return to the original deposit via TAE_TRANSACTION -> TAE_DEPOSIT; return confidence + depositor account"
        },
        {
          "id": "single_match_gate",
          "type": "condition",
          "when": "$ctx.vars.confidence != ''SINGLE''",
          "then": { "goto": "end_with_review" },
          "description": "If not exactly one match (NONE or MULTIPLE), route to operator account-selection review"
        },
        {
          "id": "dda_present_gate",
          "type": "condition",
          "when": "$ctx.vars.depositAccount == null OR $ctx.vars.depositAccount == ''''",
          "then": { "goto": "end_with_review" },
          "description": "Defensive: single match but no account resolved -> review"
        },
        {
          "id": "end_success",
          "type": "return",
          "return": { "enrichmentStatus": "EXCEPTION", "exceptionCode": "RETURNED_DEPOSIT", "exceptionDetails": "Matched to original deposit; debit depositor account" },
          "description": "Single match: exceptionCode=RETURNED_DEPOSIT so CDE dispositions RETURN; endpoint resolution sends it to terminal KILL and posting debits the depositor"
        },
        {
          "id": "end_with_review",
          "type": "return",
          "return": { "enrichmentStatus": "EXCEPTION", "exceptionCode": "ENDPOINT_REVIEW", "exceptionDetails": "Deposit match ambiguous (0 or >1); operator selects the deposit account" }
        },
        {
          "id": "end_with_match_error",
          "type": "return",
          "return": { "enrichmentStatus": "FAILED", "exceptionCode": "RETURN_MATCH_ERROR", "exceptionDetails": "match-returned-deposit endpoint error" }
        }
      ]
    }
  }'
WHERE Collection_Code IN ('INCLRF', 'INCLRB');
