-- ============================================================================
-- EIE Simulator — Exception-IN Source Configs (Returned Deposited Item replay)
-- Run against: primary (check_payment_platform) database.
-- Spec: SPEC_11_exception_in_simulator.md
--
-- Generates an INBOUND return file (INCLRF/INCLRB) from prior OUTCLEARING items so
-- the SPEC_10 returned-deposited-item pipeline can be validated end to end. Unlike
-- the OUTCLRDDA sources (04a) which stamp collectionTypeIndicator "03" (outbound
-- return, originRT 071000149), these stamp X9 collectionTypeIndicator "2" (RETURN
-- presentment) with a destinationRT of MCB (026013356) so COLLECTION_TYPE_MASTER
-- resolves type 02, and an originRT that COLLECTION_CODE_ORIGRT_REF (type 02) maps
-- UNAMBIGUOUSLY to a single inclearing-return code:
--   INCLEARING_RETURN_FED  -> originRT 021001208 -> INCLRF (Fed)
--   INCLEARING_RETURN_BANK -> originRT 041000124 -> INCLRB (bank via SVPCO)
-- (021000089 / 026009593 map to BOTH INCLRF and INCLRB — do NOT use them here.)
--
-- The return record shape is identical to the OUTCLRDDA sources: payor (drawee)
-- coordinates + a return reason. The depositor account is NOT in the file; SPEC_10
-- recovers it by matching the drawee MICR to the original ITEM_DETAILS deposit.
-- No EIE engine change: the X9 builder is fully x9Config-driven.
-- ============================================================================

-- No USE statement — pipe into the active tenant DB (mcb_check_payment_platform).

-- INCLEARING_RETURN_FED — CSV (resolves INCLRF)
INSERT INTO EIE_SOURCE_CONFIG (BANK_ID, SOURCE_ID, SOURCE_NAME, ACTIVE, CONFIG_JSON) VALUES
('BANK001', 'INCLEARING_RETURN_FED', 'Inclearing Return - Fed (INCLRF, CSV)', 1, '{
  "sourceId": "INCLEARING_RETURN_FED",
  "sourceName": "Inclearing Return - Fed (INCLRF)",
  "bankId": "BANK001",
  "collectionCode": "INCLRF",
  "fileConfig": {"format": "CSV", "encoding": "UTF-8", "delimiter": ",", "quoteChar": "\\"", "hasHeader": true},
  "fieldMapping": {"fields": [
    {"name": "transactionId", "column": "TXN_ID", "type": "string"},
    {"name": "trackingNumber", "column": "TRACKING_NUM", "type": "string"},
    {"name": "payorRT", "column": "ROUTING_NUM", "type": "string"},
    {"name": "payorAccount", "column": "ACCOUNT_NUM", "type": "string"},
    {"name": "serialNumber", "column": "CHECK_NUM", "type": "string"},
    {"name": "amount", "column": "AMOUNT", "type": "decimal"},
    {"name": "returnCode", "column": "REASON_CODE", "type": "string"},
    {"name": "returnDate", "column": "RETURN_DATE", "type": "date", "format": "yyyy-MM-dd"},
    {"name": "postingDate", "column": "POSTING_DATE", "type": "date", "format": "yyyy-MM-dd"}
  ]},
  "imageResolution": {"mode": "RESOLVE", "trackingField": "trackingNumber", "dataServicesUrl": "http://accs-data-services:8084", "resolvePath": "/api/v1/items/resolve-image"},
  "s3Config": {"inputPrefix": "exception-files/inclearing-return-fed/", "processedPrefix": "exception-files/inclearing-return-fed/processed/", "failedPrefix": "exception-files/inclearing-return-fed/failed/"},
  "batchConfig": {"maxItemCount": 100, "maxWaitMinutes": 15, "groupByDestinationRT": true, "maxCashLetterItems": 200},
  "x9Config": {
    "originRT": "021001208",
    "destinationRT": "026013356",
    "originName": "Federal Reserve",
    "destinationName": "Metropolitan Commercial Bank",
    "collectionTypeIndicator": "02",
    "maxCashLetterItems": 200,
    "maxItemsPerBundle": 50,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "02", "recordTypeIndicator": "I", "documentationTypeIndicator": "G", "fedWorkType": "C"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {"returnDetail": {
      "payorBankRoutingNumber": "$payorRT8", "payorBankCheckDigit": "$payorCheckDigit", "onUs": "$payorAccount/$serialNumber",
      "itemAmount": "$amountCents", "returnReason": "$x9ReturnCode",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "returnNotificationIndicator": "1", "archiveTypeIndicator": "", "addendumCount": 1
    }}
  },
  "pollConfig": {"intervalSeconds": 30, "enabled": true}
}'),

-- INCLEARING_RETURN_BANK — CSV (resolves INCLRB)
('BANK001', 'INCLEARING_RETURN_BANK', 'Inclearing Return - Bank/SVPCO (INCLRB, CSV)', 1, '{
  "sourceId": "INCLEARING_RETURN_BANK",
  "sourceName": "Inclearing Return - Bank/SVPCO (INCLRB)",
  "bankId": "BANK001",
  "collectionCode": "INCLRB",
  "fileConfig": {"format": "CSV", "encoding": "UTF-8", "delimiter": ",", "quoteChar": "\\"", "hasHeader": true},
  "fieldMapping": {"fields": [
    {"name": "transactionId", "column": "TXN_ID", "type": "string"},
    {"name": "trackingNumber", "column": "TRACKING_NUM", "type": "string"},
    {"name": "payorRT", "column": "ROUTING_NUM", "type": "string"},
    {"name": "payorAccount", "column": "ACCOUNT_NUM", "type": "string"},
    {"name": "serialNumber", "column": "CHECK_NUM", "type": "string"},
    {"name": "amount", "column": "AMOUNT", "type": "decimal"},
    {"name": "returnCode", "column": "REASON_CODE", "type": "string"},
    {"name": "returnDate", "column": "RETURN_DATE", "type": "date", "format": "yyyy-MM-dd"},
    {"name": "postingDate", "column": "POSTING_DATE", "type": "date", "format": "yyyy-MM-dd"}
  ]},
  "imageResolution": {"mode": "RESOLVE", "trackingField": "trackingNumber", "dataServicesUrl": "http://accs-data-services:8084", "resolvePath": "/api/v1/items/resolve-image"},
  "s3Config": {"inputPrefix": "exception-files/inclearing-return-bank/", "processedPrefix": "exception-files/inclearing-return-bank/processed/", "failedPrefix": "exception-files/inclearing-return-bank/failed/"},
  "batchConfig": {"maxItemCount": 100, "maxWaitMinutes": 15, "groupByDestinationRT": true, "maxCashLetterItems": 200},
  "x9Config": {
    "originRT": "041000124",
    "destinationRT": "026013356",
    "originName": "KeyBank (SVPCO)",
    "destinationName": "Metropolitan Commercial Bank",
    "collectionTypeIndicator": "02",
    "maxCashLetterItems": 200,
    "maxItemsPerBundle": 50,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "02", "recordTypeIndicator": "I", "documentationTypeIndicator": "G", "fedWorkType": "C"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {"returnDetail": {
      "payorBankRoutingNumber": "$payorRT8", "payorBankCheckDigit": "$payorCheckDigit", "onUs": "$payorAccount/$serialNumber",
      "itemAmount": "$amountCents", "returnReason": "$x9ReturnCode",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "returnNotificationIndicator": "1", "archiveTypeIndicator": "", "addendumCount": 1
    }}
  },
  "pollConfig": {"intervalSeconds": 30, "enabled": true}
}')

ON DUPLICATE KEY UPDATE CONFIG_JSON = VALUES(CONFIG_JSON), SOURCE_NAME = VALUES(SOURCE_NAME), UPDATED_AT = NOW();
