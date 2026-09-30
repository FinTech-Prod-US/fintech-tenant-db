-- ============================================================================
-- WORKFLOW_MASTER — FDE JSON Rule for OUTCLRDDA (Outgoing DDA Returns)
-- Run against: business_rules database
-- Additive: only inserts/updates the OUTCLRDDA row. INCLFF/OUTCLRBR untouched.
-- Spec: SPEC_workflow_master_OUTCLRDDA_FDE.md
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

-- Ensure the OUTCLRDDA MICR row has a file deadline so derive_business_day has a
-- value to compare against (decision: 23:00:00).
UPDATE COLLECTION_CODE_MICR
   SET FileDeadline = '23:00:00'
 WHERE Coll_Type = '03' AND Coll_Code = 'OUTCLRDDA' AND FileDeadline IS NULL;

INSERT INTO WORKFLOW_MASTER (Collection_Code, Name, FDE_JSON_Rule)
VALUES ('OUTCLRDDA', 'x9-file-enrichment-fde-outclearing-dda-returns', '{
  "workflow": {
    "name": "x9-file-enrichment-fde-outclearing-dda-returns",
    "scope": "perCashLetter",
    "description": "Enrich each cash letter in an OUTCLRDDA return X9 file with collection type, collection code, bin/batch ranges, and business day",
    "settings": { "timeout_ms": 1000, "stop_on_error": false },
    "steps": [
      {
        "id": "lookup_collection_type",
        "type": "sql_lookup",
        "table": "COLLECTION_TYPE_MASTER",
        "sql": "SELECT Collection_Type FROM COLLECTION_TYPE_MASTER WHERE X9_Coll_Type_Ind = :collTypeInd AND File_Dest_RT = :destRT",
        "params": {
          "collTypeInd": "$ctx.currentCL.cashLetterHeader.collectionTypeIndicator",
          "destRT": "$ctx.fileHeader.immediateDestination"
        },
        "on_success": { "save_as": "$ctx.currentCL.enrichmentData.collectionType" },
        "on_zero_match": { "goto": "end_with_error_collection_type" },
        "on_error": { "goto": "end_with_error_collection_type" }
      },
      {
        "id": "lookup_collection_code_primary",
        "type": "sql_lookup",
        "table": "COLLECTION_CODE_ORIGRT_REF",
        "sql": "SELECT Collection_Code FROM COLLECTION_CODE_ORIGRT_REF WHERE Coll_Type = :collType AND OriginRT = :originRT",
        "params": {
          "collType": "$ctx.currentCL.enrichmentData.collectionType",
          "originRT": "$ctx.fileHeader.immediateOrigin"
        },
        "on_success": { "save_as": "$ctx.currentCL.enrichmentData.collectionCode" },
        "on_zero_match": { "goto": "lookup_collection_code_fallback" },
        "on_error": { "goto": "end_with_error_collection_code" }
      },
      {
        "id": "lookup_collection_code_fallback",
        "type": "sql_lookup",
        "table": "COLLECTION_CODE_UD_REF",
        "sql": "SELECT Coll_Code FROM COLLECTION_CODE_UD_REF WHERE Coll_Type = :collType AND OriginRT = :originRT AND UserField = :userField AND FedWorkType = :fedWorkType",
        "params": {
          "collType": "$ctx.currentCL.enrichmentData.collectionType",
          "originRT": "$ctx.fileHeader.immediateOrigin",
          "userField": "$ctx.currentCL.cashLetterHeader.userField",
          "fedWorkType": "$ctx.currentCL.cashLetterHeader.fedWorkType"
        },
        "on_success": { "save_as": "$ctx.currentCL.enrichmentData.collectionCode" },
        "on_zero_match": { "goto": "end_with_error_collection_code" },
        "on_error": { "goto": "end_with_error_collection_code" }
      },
      {
        "id": "lookup_micr_range",
        "type": "sql_lookup",
        "table": "COLLECTION_CODE_MICR",
        "sql": "SELECT CONCAT(`Bin#Start`, ''-'', `Bin#End`) AS BinRange, CONCAT(BatchStart, ''-'', BatchEnd) AS BatchRange, FileDeadline FROM COLLECTION_CODE_MICR WHERE Coll_Type = :collType AND Coll_Code = :collCode",
        "params": {
          "collCode": "$ctx.currentCL.enrichmentData.collectionCode",
          "collType": "$ctx.currentCL.enrichmentData.collectionType"
        },
        "on_success": {
          "save_as": {
            "$ctx.currentCL.enrichmentData.fileDeadline": "$row.FileDeadline",
            "$ctx.currentCL.enrichmentData.assignedBinNumberRange": "$row.BinRange",
            "$ctx.currentCL.enrichmentData.assignedBatchNumberRange": "$row.BatchRange"
          }
        },
        "on_zero_match": { "goto": "end_with_error_micr_range" },
        "on_error": { "goto": "end_with_error_micr_range" }
      },
      {
        "id": "derive_business_day",
        "type": "transform",
        "logic": {
          "condition": "$ctx.fileHeader.fileCreationTime <= $ctx.currentCL.enrichmentData.fileDeadline",
          "true": "$ctx.fileHeader.fileCreationDate",
          "false": "$nextDate($ctx.fileHeader.fileCreationDate)"
        },
        "on_success": { "save_as": "$ctx.currentCL.enrichmentData.businessDay" }
      },
      {
        "id": "end_with_error_collection_type",
        "type": "return",
        "return": { "error": "COLLECTION_TYPE_NOT_FOUND", "details": "No record in COLLECTION_TYPE_MASTER" }
      },
      {
        "id": "end_with_error_collection_code",
        "type": "return",
        "return": { "error": "COLLECTION_CODE_NOT_FOUND", "details": "No matching record in COLLECTION_CODE_ORIGRT_REF or COLLECTION_CODE_UD_REF" }
      },
      {
        "id": "end_with_error_micr_range",
        "type": "return",
        "return": { "error": "MICR_RANGE_NOT_FOUND", "details": "No matching record in COLLECTION_CODE_MICR" }
      }
    ]
  }
}')
ON DUPLICATE KEY UPDATE
  Name = VALUES(Name),
  FDE_JSON_Rule = VALUES(FDE_JSON_Rule);
