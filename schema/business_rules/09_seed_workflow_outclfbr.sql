-- ============================================================================
-- WORKFLOW_MASTER — JSON Rules for OUTCLFBR (POD Branch Forward)
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

-- Update OUTCLFBR with all JSON rules
UPDATE WORKFLOW_MASTER SET
  FDE_JSON_Rule = '{
    "workflow": {
      "name": "x9-file-enrichment-fde-pod-branch",
      "scope": "perCashLetter",
      "description": "Enrich each cash letter in a POD Branch X9 file with collection type, collection code, bin/batch ranges, and business day",
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
          "on_error": { "goto": "end_with_error_collection_type" },
          "description": "Identify collection type based on CollectionTypeInd and destination RT"
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
          "on_error": { "goto": "end_with_error_collection_code" },
          "description": "Identify collection code using primary table COLLECTION_CODE_ORIGRT_REF"
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
          "on_error": { "goto": "end_with_error_collection_code" },
          "description": "Fallback lookup for collection code using COLLECTION_CODE_UD_REF"
        },
        {
          "id": "lookup_micr_range",
          "type": "sql_lookup",
          "table": "COLLECTION_CODE_MICR",
          "sql": "SELECT CONCAT(Bin_Start, ''-'', Bin_End) AS BinRange, CONCAT(BatchStart, ''-'', BatchEnd) AS BatchRange, FileDeadline FROM COLLECTION_CODE_MICR WHERE Coll_Type = :collType AND Coll_Code = :collCode",
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
          "on_error": { "goto": "end_with_error_micr_range" },
          "description": "Identify Bin/Batch number range and file deadline using COLLECTION_CODE_MICR"
        },
        {
          "id": "derive_business_day",
          "type": "transform",
          "logic": {
            "condition": "$ctx.fileHeader.fileCreationTime <= $ctx.currentCL.enrichmentData.fileDeadline",
            "true": "$ctx.fileHeader.fileCreationDate",
            "false": "$nextDate($ctx.fileHeader.fileCreationDate)"
          },
          "on_success": { "save_as": "$ctx.currentCL.enrichmentData.businessDay" },
          "description": "Determine business day based on fileCreationTime and FileDeadline"
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
  }',

  CDE_JSON_Rule = '{
    "workflow": {
      "name": "x9-item-enrichment-outclearing-pod-branch-v1",
      "scope": "perItem",
      "description": "Outclearing POD Branch item enrichment: RT validation via moov-fed, bank master check, account master (OnUs only), stop pay, fraud watch, posting code",
      "settings": { "timeout_ms": 5000, "stop_on_error": true },
      "steps": [
        {
          "id": "init_item_context",
          "type": "transform",
          "on_success": {
            "save_as": {
              "$ctx.currentItem.exceptionCode": null,
              "$ctx.currentItem.enrichmentStatus": "IN_PROGRESS",
              "$ctx.currentItem.exceptionDetails": null
            }
          },
          "description": "Initialize item enrichment output fields"
        },
        {
          "id": "validate_rt_via_moov_fed",
          "type": "api_lookup",
          "apiAlias": "moov_fed_ach_search",
          "method": "GET",
          "url": "http://accs-moov-fed:8086/fed/ach/search?routingNumber=:rt",
          "params": { "rt": "$ctx.currentItem.RT" },
          "responseMapping": {
            "participants": "achParticipants"
          },
          "on_success": {
            "save_as": {
              "$ctx.vars.fedParticipant": "$response.achParticipants[0]",
              "$ctx.currentItem.Enriched_Data_01": "$response.achParticipants[0].customerName",
              "$ctx.currentItem.Enriched_Data_02": "$response.achParticipants[0].routingNumber"
            }
          },
          "on_zero_match": { "goto": "end_with_invalid_rt" },
          "on_error": { "goto": "end_with_invalid_rt" },
          "description": "Step 1: Validate item RT against FED ACH directory via moov-fed service. If RT not found, reject as INVALID_RT"
        },
        {
          "id": "check_rt_retired",
          "type": "condition",
          "when": "$ctx.vars.fedParticipant.newRoutingNumber != ''000000000'' AND $ctx.vars.fedParticipant.newRoutingNumber != null AND $ctx.vars.fedParticipant.newRoutingNumber != ''''",
          "then": { "goto": "end_with_retired_rt" },
          "description": "Step 1b: If newRoutingNumber is non-zero, RT has been retired/merged"
        },
        {
          "id": "lookup_bank_master_rt",
          "type": "sql_lookup",
          "table": "BANK_MASTER_RT",
          "sql": "SELECT OnUsFlag, Name, Description FROM BANK_MASTER_RT WHERE RT = :rt AND InclearingFlag = ''Y'' AND Status = ''ACTIVE''",
          "params": { "rt": "$ctx.currentItem.RT" },
          "on_success": {
            "save_as": {
              "$ctx.currentItem.onUsFlag": "$row.OnUsFlag",
              "$ctx.currentItem.bankName": "$row.Name",
              "$ctx.currentItem.bankDescription": "$row.Description",
              "$ctx.currentItem.AccountClass": "DDA",
              "$ctx.currentItem.Enriched_Data_03": "$row.OnUsFlag",
              "$ctx.currentItem.Enriched_Data_04": "$row.Name"
            }
          },
          "on_zero_match": {
            "save_as": {
              "$ctx.currentItem.onUsFlag": "N",
              "$ctx.currentItem.AccountClass": "DDA",
              "$ctx.currentItem.Enriched_Data_03": "N"
            },
            "goto": "lookup_posting_code"
          },
          "on_error": {
            "save_as": {
              "$ctx.currentItem.onUsFlag": "N",
              "$ctx.currentItem.AccountClass": "DDA",
              "$ctx.currentItem.Enriched_Data_03": "N"
            },
            "goto": "lookup_posting_code"
          },
          "description": "Step 2: Bank Master RT lookup. If match with InclearingFlag=Y then OnUs=YES (check drawn on MCB), else OnUs=NO (transit item). Transit items skip to posting code."
        },
        {
          "id": "onus_gate",
          "type": "condition",
          "when": "$ctx.currentItem.onUsFlag != ''Y''",
          "then": { "goto": "lookup_posting_code" },
          "description": "If OnUs=NO (transit item), skip account/stop-pay/fraud checks and go directly to posting code"
        },
        {
          "id": "lookup_account_master",
          "type": "sql_lookup",
          "table": "ALL_ACCOUNT_MASTER",
          "sql": "SELECT AccountClass, ProductType, BranchCode, Currency, Status, CustomerID, CustomerName, PositivePayFlag, Check_Deposit_Limit FROM ALL_ACCOUNT_MASTER WHERE RT = :rt AND AccountNumber = :acct",
          "params": {
            "rt": "$ctx.currentItem.RT",
            "acct": "$ctx.currentItem.AccountNumber"
          },
          "on_success": { "save_as": "$ctx.vars.account" },
          "on_zero_match": { "goto": "end_with_account_not_found" },
          "on_error": { "goto": "end_with_account_not_found" },
          "description": "Step 3: Account Master lookup for OnUs items. Validate account exists for RT + AccountNumber"
        },
        {
          "id": "account_status_closed_gate",
          "type": "condition",
          "when": "$ctx.vars.account.Status == ''CLOSED''",
          "then": { "goto": "end_with_account_closed" },
          "description": "Stop enrichment if account is CLOSED"
        },
        {
          "id": "account_status_frozen_gate",
          "type": "condition",
          "when": "$ctx.vars.account.Status == ''FROZEN''",
          "then": { "goto": "end_with_account_frozen" },
          "description": "Stop enrichment if account is FROZEN"
        },
        {
          "id": "deposit_limit_gate",
          "type": "condition",
          "when": "$ctx.currentItem.Amount > $ctx.vars.account.Check_Deposit_Limit",
          "then": { "goto": "end_with_exceed_item_limit" },
          "description": "Stop enrichment if item amount exceeds Check_Deposit_Limit"
        },
        {
          "id": "save_account_fields",
          "type": "transform",
          "on_success": {
            "save_as": {
              "$ctx.currentItem.AccountClass": "$ctx.vars.account.AccountClass",
              "$ctx.currentItem.ProductType": "$ctx.vars.account.ProductType",
              "$ctx.currentItem.BranchCode": "$ctx.vars.account.BranchCode",
              "$ctx.currentItem.Currency": "$ctx.vars.account.Currency",
              "$ctx.currentItem.CustomerID": "$ctx.vars.account.CustomerID",
              "$ctx.currentItem.CustomerName": "$ctx.vars.account.CustomerName",
              "$ctx.currentItem.AccountStatus": "$ctx.vars.account.Status",
              "$ctx.currentItem.PositivePayFlag": "$ctx.vars.account.PositivePayFlag",
              "$ctx.currentItem.Check_Deposit_Limit": "$ctx.vars.account.Check_Deposit_Limit",
              "$ctx.currentItem.Enriched_Data_05": "$ctx.vars.account.AccountClass",
              "$ctx.currentItem.Enriched_Data_06": "$ctx.vars.account.ProductType",
              "$ctx.currentItem.Enriched_Data_07": "$ctx.vars.account.BranchCode",
              "$ctx.currentItem.Enriched_Data_08": "$ctx.vars.account.Currency",
              "$ctx.currentItem.Enriched_Data_09": "$ctx.vars.account.Status",
              "$ctx.currentItem.Enriched_Data_10": "$ctx.vars.account.CustomerID",
              "$ctx.currentItem.Enriched_Data_11": "$ctx.vars.account.CustomerName",
              "$ctx.currentItem.Enriched_Data_12": "$ctx.vars.account.Check_Deposit_Limit"
            }
          },
          "description": "Copy account master fields into item payload for OnUs items"
        },
        {
          "id": "lookup_stop_pay",
          "type": "sql_lookup",
          "table": "STOP_PAY_REF",
          "sql": "SELECT StopReasonCode, StopDate, Active FROM STOP_PAY_REF WHERE RT = :rt AND AccountNumber = :acct AND CheckSerialNumber = :serial AND Active = ''Y''",
          "params": {
            "rt": "$ctx.currentItem.RT",
            "acct": "$ctx.currentItem.AccountNumber",
            "serial": "$ctx.currentItem.CheckSerialNumber"
          },
          "on_success": {
            "save_as": {
              "$ctx.currentItem.StopPay_StopReasonCode": "$row.StopReasonCode",
              "$ctx.currentItem.StopPay_StopDate": "$row.StopDate",
              "$ctx.currentItem.Enriched_Data_13": "$row.StopReasonCode",
              "$ctx.currentItem.Enriched_Data_14": "$row.StopDate"
            },
            "goto": "end_with_stop_pay_return"
          },
          "on_zero_match": { "goto": "lookup_fraud_watch" },
          "on_error": { "goto": "lookup_fraud_watch" },
          "description": "Step 4: Stop Pay check for OnUs items. If match found, reject with STOP_PAY_RETURN"
        },
        {
          "id": "lookup_fraud_watch",
          "type": "sql_lookup",
          "table": "FRAUD_WATCH_REF",
          "sql": "SELECT FraudFlagType, FraudReasonCode FROM FRAUD_WATCH_REF WHERE RT = :rt AND AccountNumber = :acct AND SerialNumber = :serial",
          "params": {
            "rt": "$ctx.currentItem.RT",
            "acct": "$ctx.currentItem.AccountNumber",
            "serial": "$ctx.currentItem.CheckSerialNumber"
          },
          "on_success": {
            "save_as": {
              "$ctx.currentItem.FraudFlagType": "$row.FraudFlagType",
              "$ctx.currentItem.FraudReasonCode": "$row.FraudReasonCode",
              "$ctx.currentItem.Enriched_Data_15": "$row.FraudFlagType",
              "$ctx.currentItem.Enriched_Data_16": "$row.FraudReasonCode"
            },
            "goto": "end_with_counterfeit_suspected"
          },
          "on_zero_match": { "goto": "lookup_posting_code" },
          "on_error": { "goto": "lookup_posting_code" },
          "description": "Step 5: Fraud Watch check for OnUs items. If match found, reject with COUNTERFEIT_SUSPECTED"
        },
        {
          "id": "lookup_posting_code",
          "type": "sql_lookup",
          "table": "POSTING_CODE_REF",
          "sql": "SELECT TranCode, DebitCreditInd, GLAccount, Description FROM POSTING_CODE_REF WHERE RT = :rt AND AccountClass = :acctClass AND Active = ''Y''",
          "params": {
            "rt": "$ctx.currentItem.RT",
            "acctClass": "$ctx.currentItem.AccountClass"
          },
          "on_success": {
            "save_as": {
              "$ctx.currentItem.Posting_TranCode": "$row.TranCode",
              "$ctx.currentItem.Posting_DebitCreditInd": "$row.DebitCreditInd",
              "$ctx.currentItem.Posting_GLAccount": "$row.GLAccount",
              "$ctx.currentItem.Posting_Description": "$row.Description",
              "$ctx.currentItem.Enriched_Data_17": "$row.TranCode",
              "$ctx.currentItem.Enriched_Data_18": "$row.DebitCreditInd",
              "$ctx.currentItem.Enriched_Data_19": "$row.GLAccount",
              "$ctx.currentItem.Enriched_Data_20": "$row.Description"
            },
            "goto": "end_success"
          },
          "on_zero_match": { "goto": "end_with_posting_code_error" },
          "on_error": { "goto": "end_with_posting_code_error" },
          "description": "Step 6: Posting Code lookup by RT + AccountClass. For OnUs items uses AccountClass from Account Master, for transit items uses DDA default"
        },
        {
          "id": "end_success",
          "type": "return",
          "return": { "enrichmentStatus": "SUCCESS", "exceptionCode": null, "exceptionDetails": null }
        },
        {
          "id": "end_with_invalid_rt",
          "type": "return",
          "return": { "error": "INVALID_RT", "details": "RT not found in FED ACH directory" }
        },
        {
          "id": "end_with_retired_rt",
          "type": "return",
          "return": { "error": "RETIRED_RT", "details": "RT has been retired/merged — newRoutingNumber is set in FED directory" }
        },
        {
          "id": "end_with_account_not_found",
          "type": "return",
          "return": { "error": "ACCOUNT_NOT_FOUND", "details": "No match in ALL_ACCOUNT_MASTER for OnUs item" }
        },
        {
          "id": "end_with_account_closed",
          "type": "return",
          "return": { "error": "ACCOUNT_CLOSED", "details": "Account status is CLOSED" }
        },
        {
          "id": "end_with_account_frozen",
          "type": "return",
          "return": { "error": "ACCOUNT_FROZEN", "details": "Account status is FROZEN" }
        },
        {
          "id": "end_with_exceed_item_limit",
          "type": "return",
          "return": { "error": "EXCEED_ITEM_LIMIT", "details": "Item amount exceeded Check_Deposit_Limit" }
        },
        {
          "id": "end_with_stop_pay_return",
          "type": "return",
          "return": { "error": "STOP_PAY_RETURN", "details": "Matched active STOP_PAY_REF record" }
        },
        {
          "id": "end_with_counterfeit_suspected",
          "type": "return",
          "return": { "error": "COUNTERFEIT_SUSPECTED", "details": "Matched FRAUD_WATCH_REF record" }
        },
        {
          "id": "end_with_posting_code_error",
          "type": "return",
          "return": { "error": "BR_DATA_POSTING_CODE_ERROR", "details": "No match in POSTING_CODE_REF for RT + AccountClass" }
        }
      ]
    }
  }',

  IQV_JSON_Rule = '{
    "collectionCodeMap": {
      "OUTCLFBR": {
        "tiffValidation": true,
        "iqa": true,
        "iua": false,
        "fraud": false,
        "iuaOcr": false
      }
    }
  }',

  DQV_JSON_Rule = '{
    "validationRules": [
      {
        "validationType": "ACCOUNT_VALIDATION",
        "ruleName": "account_missing_check",
        "field": "ACCOUNT",
        "required": true,
        "errorCode": "DQV_ACC_001",
        "errorMessage": "Account number is missing in both ORIG and OCR",
        "parameters": { "sources": ["ORIG_MICR_ACCOUNT", "OCR_MICR_ACCOUNT"], "checkBothSources": true }
      },
      {
        "validationType": "ACCOUNT_VALIDATION",
        "ruleName": "account_format_validation",
        "field": "ACCOUNT",
        "errorCode": "DQV_ACC_002",
        "errorMessage": "Invalid account format",
        "parameters": { "minLength": 4, "maxLength": 17, "allowOnlyDigits": true, "rejectAllZeros": true, "rejectRepeatedDigits": true, "rejectSpecialMicrChars": true, "specialChars": ["*", "-", "?", "#", "@", "!", "&", "%"] }
      },
      {
        "validationType": "ACCOUNT_VALIDATION",
        "ruleName": "account_conflict_check",
        "field": "ACCOUNT",
        "errorCode": "DQV_ACC_004",
        "errorMessage": "Account number conflict between ORIG and OCR",
        "parameters": { "compareFields": ["ORIG_MICR_ACCOUNT", "OCR_MICR_ACCOUNT"], "conflictAction": "DATA_CORRECTION" }
      },
      {
        "validationType": "AMOUNT_VALIDATION",
        "ruleName": "amount_missing_check",
        "field": "AMOUNT",
        "required": true,
        "errorCode": "DQV_AMT_001",
        "errorMessage": "Amount is missing in all sources",
        "parameters": { "sources": ["AMOUNT", "ORIG_MICR_AMOUNT", "OCR_MICR_AMOUNT"], "checkAllSources": true }
      },
      {
        "validationType": "AMOUNT_VALIDATION",
        "ruleName": "amount_range_validation",
        "field": "AMOUNT",
        "minValue": 0.01,
        "maxValue": 1000000.0,
        "errorCode": "DQV_AMT_002",
        "errorMessage": "Amount must be positive and within limits",
        "parameters": { "rejectZero": true, "rejectNegative": true }
      },
      {
        "validationType": "AMOUNT_VALIDATION",
        "ruleName": "amount_conflict_check",
        "field": "AMOUNT",
        "tolerance": 1.0,
        "errorCode": "DQV_AMT_005",
        "errorMessage": "Amount conflict between sources",
        "parameters": { "compareFields": ["AMOUNT", "ORIG_MICR_AMOUNT", "OCR_MICR_AMOUNT"], "conflictAction": "DATA_CORRECTION", "toleranceAmount": 1.0 }
      },
      {
        "validationType": "RT_VALIDATION",
        "ruleName": "rt_missing_check",
        "field": "RT",
        "required": true,
        "errorCode": "DQV_RT_001",
        "errorMessage": "Routing Transit number is missing",
        "parameters": { "sources": ["ORIG_MICR_RT", "OCR_MICR_RT"], "checkBothSources": true }
      },
      {
        "validationType": "RT_VALIDATION",
        "ruleName": "rt_format_and_mod10_validation",
        "field": "RT",
        "pattern": "^\\\\d{9}$",
        "errorCode": "DQV_RT_002",
        "errorMessage": "Invalid RT format or mod-10 check failed",
        "parameters": { "length": 9, "allowOnlyDigits": true, "performMod10Check": true, "mod10Algorithm": "ABA_ROUTING_NUMBER", "mod10Weights": [3, 7, 1, 3, 7, 1, 3, 7, 1], "rejectSpecialMicrChars": true, "specialChars": ["*", "-", "?", "#", "@", "!", "&", "%"] }
      },
      {
        "validationType": "RT_VALIDATION",
        "ruleName": "rt_conflict_check",
        "field": "RT",
        "errorCode": "DQV_RT_004",
        "errorMessage": "RT conflict between ORIG and OCR",
        "parameters": { "compareFields": ["ORIG_MICR_RT", "OCR_MICR_RT"], "conflictAction": "DATA_CORRECTION" }
      },
      {
        "validationType": "CHECK_NUMBER_VALIDATION",
        "ruleName": "check_number_validation",
        "field": "CHECK_NUMBER",
        "errorCode": "DQV_CHK_001",
        "errorMessage": "Invalid check number format",
        "parameters": { "maxLength": 10, "allowOnlyNumeric": true, "requiredIfPresent": false }
      },
      {
        "validationType": "CUSTOM",
        "ruleName": "MICR_SPECIAL_CHAR_CHECK",
        "field": "ALL_MICR_FIELDS",
        "errorCode": "DQV_MICR_001",
        "errorMessage": "MICR field contains special characters indicating OCR uncertainty",
        "parameters": { "fields": ["ORIG_MICR_ONUS", "ORIG_MICR_EPC", "ORIG_MICR_AUXONUS", "OCR_MICR_PC", "OCR_MICR_EPC", "OCR_MICR_AUXONUS", "OCR_MICR_FIELD4"], "specialChars": ["*", "-", "?", "#", "@", "!", "&", "%"] }
      }
    ]
  }',

  ImageArchive_JSON_Rule = '{
    "outputFormats": ["CIFF", "COF"],
    "ciffConfig": {
      "originatorId": "CCP_ARCHIVE",
      "formatVersion": "CIFF-1.0"
    },
    "cofConfig": {
      "includeHeader": true,
      "fieldDelimiter": "\\t"
    },
    "metadataFields": [
      "RT", "ACCOUNT_NUMBER", "AMOUNT", "ON_US", "AUX_ON_US", "EPC",
      "ENRICHED_DATA_01", "ENRICHED_DATA_02", "ENRICHED_DATA_03",
      "ENRICHED_DATA_04", "ENRICHED_DATA_05",
      "PROCESSING_STATUS", "EXCEPTION_CODE", "COLLECTION_CODE",
      "BUSINESS_DATE", "FILE_ID", "CASHLETTER_ID", "BUNDLE_ID", "PAYMENT_ID",
      "CHANNEL", "BRANCH_CODE", "DEPOSITOR_ACCOUNT", "TELLER_ID", "ATM_ID"
    ]
  }'

WHERE Collection_Code = 'OUTCLFBR';

