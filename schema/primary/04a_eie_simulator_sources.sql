-- ============================================================================
-- EIE Simulator — Source Configurations wired to OUTCLRDDA (Outgoing Return DDA)
-- Run against: check_payment_platform database
--
-- The base 04_eie_schema_and_seed.sql sources use originRT 061000146 (which the
-- collection-code reference maps to FORWARD codes). The EIE Return Simulator
-- needs sources whose X9 originRT is 071000140 so the generated return X9 routes
-- as collection code OUTCLRDDA (Coll_Type 03, Outgoing Return - Core Banking DDA;
-- see business_rules/06_seed_tae_eie.sql). One source per file format so the
-- operator can exercise CSV / JSON / FLAT through the simulator.
--
-- Accs-Server's EIE module builds the exception file from each source's
-- fieldMapping (single source of truth) and drops it under s3Config.inputPrefix;
-- the EIE poller (or a manual flush) then builds the X9 and hands it to Data
-- Ingestion. collectionTypeIndicator "03" = returns; originRT 071000140 = the
-- OUTCLRDDA origin.
-- ============================================================================

-- NOTE: no USE statement — apply this against the active tenant DB (e.g.
-- mcb_check_payment_platform locally). Piping into the target DB keeps it portable.

-- Return-code mappings already seeded in 04_eie_schema_and_seed.sql; re-assert
-- the core DDA posting exceptions in case this file is run standalone.
INSERT INTO EIE_RETURN_CODE_MAPPING (BANK_ID, SOURCE_CODE, SOURCE_DESCRIPTION, X9_RETURN_CODE, X9_DESCRIPTION) VALUES
('BANK001', 'NSF',         'Non-Sufficient Funds',          'R01', 'Insufficient Funds'),
('BANK001', 'UNCOLL',      'Uncollected Funds',             'R09', 'Uncollected Funds'),
('BANK001', 'STOP_PAY',    'Stop Payment',                  'R06', 'Returned per ODFI Request'),
('BANK001', 'PAY_STOPPED', 'Payment Stopped',               'R08', 'Payment Stopped'),
('BANK001', 'ACCT_CLOSED', 'Account Closed',                'R02', 'Account Closed'),
('BANK001', 'NO_ACCT',     'No Account/Unable to Locate',   'R03', 'No Account/Unable to Locate Account'),
('BANK001', 'FROZEN',      'Account Frozen',                'R16', 'Account Frozen'),
('BANK001', 'REFER_MAKER', 'Refer to Maker',                'R29', 'Corporate Customer Advises Not Authorized')
ON DUPLICATE KEY UPDATE X9_RETURN_CODE = VALUES(X9_RETURN_CODE), X9_DESCRIPTION = VALUES(X9_DESCRIPTION);

-- ============================================================================
-- CORE_BANKING_DDA — CSV (primary simulator source, OUTCLRDDA)
-- ============================================================================
INSERT INTO EIE_SOURCE_CONFIG (BANK_ID, SOURCE_ID, SOURCE_NAME, ACTIVE, CONFIG_JSON) VALUES
('BANK001', 'CORE_BANKING_DDA', 'Core Banking DDA - Outgoing Returns (OUTCLRDDA, CSV)', 1, '{
  "sourceId": "CORE_BANKING_DDA",
  "sourceName": "Core Banking DDA - Outgoing Returns",
  "bankId": "BANK001",
  "collectionCode": "OUTCLRDDA",
  "fileConfig": {"format": "CSV", "encoding": "UTF-8", "delimiter": ",", "quoteChar": "\\"", "hasHeader": true},
  "fieldMapping": {"fields": [
    {"name": "transactionId", "column": "TXN_ID", "type": "string"},
    {"name": "payorRT", "column": "ROUTING_NUM", "type": "string"},
    {"name": "payorAccount", "column": "ACCOUNT_NUM", "type": "string"},
    {"name": "serialNumber", "column": "CHECK_NUM", "type": "string"},
    {"name": "amount", "column": "AMOUNT", "type": "decimal"},
    {"name": "returnCode", "column": "REASON_CODE", "type": "string"},
    {"name": "returnDate", "column": "RETURN_DATE", "type": "date", "format": "yyyy-MM-dd"},
    {"name": "postingDate", "column": "POSTING_DATE", "type": "date", "format": "yyyy-MM-dd"}
  ]},
  "imageResolution": {"mode": "API_LOOKUP", "lookupField": "transactionId", "dataServicesUrl": "http://accs-data-services:8084", "imagePath": "/api/v1/items/{id}/images"},
  "s3Config": {"inputPrefix": "exception-files/core-banking-dda/", "processedPrefix": "exception-files/core-banking-dda/processed/", "failedPrefix": "exception-files/core-banking-dda/failed/"},
  "batchConfig": {"maxItemCount": 100, "maxWaitMinutes": 15, "groupByDestinationRT": true, "maxCashLetterItems": 200},
  "x9Config": {
    "originRT": "071000149",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "03",
    "maxCashLetterItems": 200,
    "maxItemsPerBundle": 50,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "03", "recordTypeIndicator": "I", "documentationTypeIndicator": "G"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {"returnDetail": {
      "payorBankRoutingNumber": "$payorRT", "payorBankCheckDigit": "", "onUs": "$payorAccount/$serialNumber",
      "itemAmount": "$amountCents", "returnReason": "$x9ReturnCode",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "returnNotificationIndicator": "1", "archiveTypeIndicator": "", "addendumCount": 1
    }}
  },
  "pollConfig": {"intervalSeconds": 30, "enabled": true}
}'),

-- ============================================================================
-- CORE_BANKING_DDA_JSON — JSON (OUTCLRDDA)
-- ============================================================================
('BANK001', 'CORE_BANKING_DDA_JSON', 'Core Banking DDA - Outgoing Returns (OUTCLRDDA, JSON)', 1, '{
  "sourceId": "CORE_BANKING_DDA_JSON",
  "sourceName": "Core Banking DDA - Outgoing Returns (JSON)",
  "bankId": "BANK001",
  "collectionCode": "OUTCLRDDA",
  "fileConfig": {"format": "JSON", "encoding": "UTF-8", "recordsPath": "returns"},
  "fieldMapping": {"fields": [
    {"name": "transactionId", "jsonPath": "txnId", "type": "string"},
    {"name": "payorRT", "jsonPath": "routingNumber", "type": "string"},
    {"name": "payorAccount", "jsonPath": "accountNumber", "type": "string"},
    {"name": "serialNumber", "jsonPath": "checkSerial", "type": "string"},
    {"name": "amount", "jsonPath": "checkAmount", "type": "decimal"},
    {"name": "returnCode", "jsonPath": "reasonCode", "type": "string"},
    {"name": "returnDate", "jsonPath": "returnDate", "type": "date", "format": "yyyy-MM-dd"},
    {"name": "postingDate", "jsonPath": "postingDate", "type": "date", "format": "yyyy-MM-dd"}
  ]},
  "imageResolution": {"mode": "API_LOOKUP", "lookupField": "transactionId", "dataServicesUrl": "http://accs-data-services:8084", "imagePath": "/api/v1/items/{id}/images"},
  "s3Config": {"inputPrefix": "exception-files/core-banking-dda-json/", "processedPrefix": "exception-files/core-banking-dda-json/processed/", "failedPrefix": "exception-files/core-banking-dda-json/failed/"},
  "batchConfig": {"maxItemCount": 100, "maxWaitMinutes": 15, "groupByDestinationRT": true, "maxCashLetterItems": 200},
  "x9Config": {
    "originRT": "071000149",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "03",
    "maxCashLetterItems": 200,
    "maxItemsPerBundle": 50,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "03", "recordTypeIndicator": "I", "documentationTypeIndicator": "G"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {"returnDetail": {
      "payorBankRoutingNumber": "$payorRT", "payorBankCheckDigit": "", "onUs": "$payorAccount/$serialNumber",
      "itemAmount": "$amountCents", "returnReason": "$x9ReturnCode",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "returnNotificationIndicator": "1", "archiveTypeIndicator": "", "addendumCount": 1
    }}
  },
  "pollConfig": {"intervalSeconds": 30, "enabled": true}
}'),

-- ============================================================================
-- CORE_BANKING_DDA_FLAT — Fixed-width FLAT (OUTCLRDDA)
-- ============================================================================
('BANK001', 'CORE_BANKING_DDA_FLAT', 'Core Banking DDA - Outgoing Returns (OUTCLRDDA, FLAT)', 1, '{
  "sourceId": "CORE_BANKING_DDA_FLAT",
  "sourceName": "Core Banking DDA - Outgoing Returns (FLAT)",
  "bankId": "BANK001",
  "collectionCode": "OUTCLRDDA",
  "fileConfig": {"format": "FLAT", "encoding": "UTF-8", "hasHeader": true, "headerLines": 1, "hasTrailer": true, "trailerLines": 1},
  "fieldMapping": {"fields": [
    {"name": "transactionId", "start": 1, "end": 20, "type": "string", "trim": true},
    {"name": "payorRT", "start": 21, "end": 29, "type": "string"},
    {"name": "payorAccount", "start": 30, "end": 49, "type": "string", "trim": true},
    {"name": "serialNumber", "start": 50, "end": 64, "type": "string", "trim": true},
    {"name": "amount", "start": 65, "end": 76, "type": "decimal", "impliedDecimals": 2},
    {"name": "returnCode", "start": 77, "end": 80, "type": "string", "trim": true},
    {"name": "returnDate", "start": 81, "end": 88, "type": "date", "format": "yyyyMMdd"},
    {"name": "originalFileId", "start": 89, "end": 100, "type": "long"},
    {"name": "originalItemSeq", "start": 101, "end": 106, "type": "int"}
  ]},
  "imageResolution": {"mode": "API_LOOKUP", "lookupField": "transactionId", "dataServicesUrl": "http://accs-data-services:8084", "imagePath": "/api/v1/items/{id}/images"},
  "s3Config": {"inputPrefix": "exception-files/core-banking-dda-flat/", "processedPrefix": "exception-files/core-banking-dda-flat/processed/", "failedPrefix": "exception-files/core-banking-dda-flat/failed/"},
  "batchConfig": {"maxItemCount": 100, "maxWaitMinutes": 15, "groupByDestinationRT": true, "maxCashLetterItems": 200},
  "x9Config": {
    "originRT": "071000149",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "03",
    "maxCashLetterItems": 200,
    "maxItemsPerBundle": 50,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "03", "recordTypeIndicator": "I", "documentationTypeIndicator": "G"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {"returnDetail": {
      "payorBankRoutingNumber": "$payorRT", "payorBankCheckDigit": "", "onUs": "$payorAccount/$serialNumber",
      "itemAmount": "$amountCents", "returnReason": "$x9ReturnCode",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "returnNotificationIndicator": "1", "archiveTypeIndicator": "", "addendumCount": 1
    }}
  },
  "pollConfig": {"intervalSeconds": 30, "enabled": true}
}')

ON DUPLICATE KEY UPDATE CONFIG_JSON = VALUES(CONFIG_JSON), SOURCE_NAME = VALUES(SOURCE_NAME), UPDATED_AT = NOW();
