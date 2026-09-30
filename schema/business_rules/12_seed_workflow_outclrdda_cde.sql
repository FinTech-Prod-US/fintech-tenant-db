-- ============================================================================
-- WORKFLOW_MASTER — CDE JSON Rule for OUTCLRDDA (parent enrichment)
-- Run against: business_rules database. UPDATE only; OUTCLRDDA row must exist.
-- Spec: SPEC_workflow_master_OUTCLRDDA_CDE.md (with GAP 5 unified ENDPOINT_REVIEW)
--
-- One api_lookup to Data Services /items/return-parent-enrichment resolves the
-- parent item (via ITEM_DETAILS_REC 32/34) and returns OnUs flag + BOFD RT, both
-- mapped into the return item's Enriched_Data_01 / Enriched_Data_02. Missing BOFD
-- RT routes to the single unified review destination ENDPOINT_REVIEW.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

UPDATE WORKFLOW_MASTER SET
  CDE_JSON_Rule = '{
    "workflow": {
      "name": "x9-item-enrichment-outclearing-dda-returns-v1",
      "scope": "perItem",
      "description": "OUTCLRDDA return item enrichment: resolve parent item, populate OnUs indicator + BOFD RT; unified ENDPOINT_REVIEW if BOFD RT missing",
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
          "id": "resolve_parent_enrichment",
          "type": "api_lookup",
          "method": "GET",
          "url": "http://accs-mcb-data-services:8084/api/v1/items/return-parent-enrichment?returnPaymentId=:returnPaymentId",
          "params": { "returnPaymentId": "$ctx.currentItem.paymentId" },
          "on_success": { "save_as": {
            "$ctx.currentItem.Enriched_Data_01": "$response.onUsIndicator",
            "$ctx.currentItem.Enriched_Data_02": "$response.bofdRt",
            "$ctx.vars.resolved": "$response.resolved",
            "$ctx.vars.bofdRt": "$response.bofdRt"
          }},
          "on_error": { "goto": "end_with_parent_lookup_error" },
          "description": "Single call: resolve parent item (via ITEM_DETAILS_REC 32/34) and return OnUs indicator + BOFD RT"
        },
        {
          "id": "parent_found_gate",
          "type": "condition",
          "when": "$ctx.vars.resolved == false",
          "then": { "goto": "end_with_parent_not_found" },
          "description": "If no parent resolved, terminal exception"
        },
        {
          "id": "bofd_rt_gate",
          "type": "condition",
          "when": "$ctx.vars.bofdRt == null OR $ctx.vars.bofdRt == ''''",
          "then": { "goto": "end_with_endpoint_review" },
          "description": "If BOFD RT missing, route to unified ENDPOINT_REVIEW (operator keys BOFD RT)"
        },
        {
          "id": "end_success",
          "type": "return",
          "return": { "enrichmentStatus": "SUCCESS", "exceptionCode": null, "exceptionDetails": null }
        },
        {
          "id": "end_with_endpoint_review",
          "type": "return",
          "return": { "enrichmentStatus": "EXCEPTION", "exceptionCode": "ENDPOINT_REVIEW", "exceptionDetails": "Parent BOFD RT not found; route to unified review (operator keys BOFD RT)" }
        },
        {
          "id": "end_with_parent_not_found",
          "type": "return",
          "return": { "enrichmentStatus": "EXCEPTION", "exceptionCode": "PARENT_ITEM_NOT_FOUND", "exceptionDetails": "No parent item resolved from ITEM_DETAILS_REC 32/34" }
        },
        {
          "id": "end_with_parent_lookup_error",
          "type": "return",
          "return": { "enrichmentStatus": "FAILED", "exceptionCode": "PARENT_LOOKUP_ERROR", "exceptionDetails": "return-parent-enrichment endpoint error" }
        }
      ]
    }
  }'
WHERE Collection_Code = 'OUTCLRDDA';
