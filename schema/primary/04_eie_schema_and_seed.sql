-- ============================================================================
-- EIE Engine — Schema + Seed Data
-- Run against: check_payment_platform database
-- ============================================================================

USE ${DB_NAME_PRIMARY};

-- ============================================================================
-- SCHEMA
-- ============================================================================

CREATE TABLE IF NOT EXISTS EIE_SOURCE_CONFIG (
    CONFIG_ID           BIGINT AUTO_INCREMENT PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    SOURCE_ID           VARCHAR(50) NOT NULL,
    SOURCE_NAME         VARCHAR(100) NOT NULL,
    ACTIVE              TINYINT(1) NOT NULL DEFAULT 1,
    CONFIG_JSON         JSON NOT NULL,
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bank_source (BANK_ID, SOURCE_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS EIE_RETURN_CODE_MAPPING (
    MAPPING_ID          BIGINT AUTO_INCREMENT PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    SOURCE_CODE         VARCHAR(20) NOT NULL,
    SOURCE_DESCRIPTION  VARCHAR(200),
    X9_RETURN_CODE      VARCHAR(5) NOT NULL,
    X9_DESCRIPTION      VARCHAR(200) NOT NULL,
    ACTIVE              TINYINT(1) NOT NULL DEFAULT 1,
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bank_code (BANK_ID, SOURCE_CODE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS EIE_FILE_TRACKING (
    FILE_ID             BIGINT AUTO_INCREMENT PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    SOURCE_ID           VARCHAR(50) NOT NULL,
    FILE_NAME           VARCHAR(500) NOT NULL,
    S3_KEY              VARCHAR(500) NOT NULL,
    STATUS              VARCHAR(20) NOT NULL DEFAULT 'DETECTED',
    RECORD_COUNT        INT DEFAULT 0,
    PARSED_COUNT        INT DEFAULT 0,
    FAILED_COUNT        INT DEFAULT 0,
    ERROR_MESSAGE       VARCHAR(1000),
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_eie_file_status (STATUS),
    INDEX idx_eie_file_bank_source (BANK_ID, SOURCE_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS EIE_RETURN_ITEM (
    ITEM_ID             BIGINT AUTO_INCREMENT PRIMARY KEY,
    RETURN_ITEM_ID      VARCHAR(64) NOT NULL UNIQUE,
    BANK_ID             VARCHAR(20) NOT NULL,
    SOURCE_ID           VARCHAR(50) NOT NULL,
    FILE_ID             BIGINT NOT NULL,
    STATUS              VARCHAR(20) NOT NULL DEFAULT 'STAGED',
    ORIGINAL_ITEM_ID    VARCHAR(64),
    ORIGINAL_FILE_ID    BIGINT,
    ORIGINAL_ITEM_SEQ   INT,
    PAYOR_RT            VARCHAR(9),
    PAYOR_ACCOUNT       VARCHAR(20),
    SERIAL_NUMBER       VARCHAR(15),
    ITEM_AMOUNT         DECIMAL(12,2) NOT NULL,
    SOURCE_RETURN_CODE  VARCHAR(20),
    X9_RETURN_CODE      VARCHAR(5),
    RETURN_REASON       VARCHAR(200),
    RETURN_DATE         DATE,
    FRONT_IMAGE_S3_URI  VARCHAR(500),
    BACK_IMAGE_S3_URI   VARCHAR(500),
    IMAGE_RESOLUTION_MODE VARCHAR(20),
    DESTINATION_RT      VARCHAR(9),
    BATCH_ID            VARCHAR(64),
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_eie_item_status (BANK_ID, STATUS),
    INDEX idx_eie_item_batch (BATCH_ID),
    INDEX idx_eie_item_file (FILE_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS EIE_BATCH (
    BATCH_ID            VARCHAR(64) PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    SOURCE_ID           VARCHAR(50) NOT NULL,
    DESTINATION_RT      VARCHAR(9),
    STATUS              VARCHAR(20) NOT NULL DEFAULT 'FLUSHING',
    ITEM_COUNT          INT NOT NULL DEFAULT 0,
    TOTAL_AMOUNT        DECIMAL(14,2) DEFAULT 0,
    X9_FILE_NAME        VARCHAR(200),
    X9_FILE_S3_URI      VARCHAR(500),
    X9_FILE_SIZE_BYTES  BIGINT,
    INGESTION_FILE_ID   BIGINT,
    CASH_LETTER_COUNT   INT DEFAULT 1,
    ERROR_MESSAGE       VARCHAR(1000),
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_eie_batch_status (STATUS)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- SEED: Return Code Mappings for BANK001
-- ============================================================================

INSERT INTO EIE_RETURN_CODE_MAPPING (BANK_ID, SOURCE_CODE, SOURCE_DESCRIPTION, X9_RETURN_CODE, X9_DESCRIPTION) VALUES
('BANK001', 'NSF', 'Non-Sufficient Funds', 'R01', 'Insufficient Funds'),
('BANK001', 'INSF', 'Insufficient Funds', 'R01', 'Insufficient Funds'),
('BANK001', 'ACCT_CLOSED', 'Account Closed', 'R02', 'Account Closed'),
('BANK001', 'CLOSED', 'Account Closed', 'R02', 'Account Closed'),
('BANK001', 'NO_ACCT', 'No Account/Unable to Locate', 'R03', 'No Account/Unable to Locate Account'),
('BANK001', 'INVALID_ACCT', 'Invalid Account Number', 'R04', 'Invalid Account Number'),
('BANK001', 'UNAUTH', 'Unauthorized Debit', 'R05', 'Unauthorized Debit to Consumer Account'),
('BANK001', 'STOP_PAY', 'Stop Payment', 'R06', 'Returned per ODFI Request'),
('BANK001', 'STOP', 'Stop Payment', 'R06', 'Returned per ODFI Request'),
('BANK001', 'AUTH_REVOKED', 'Authorization Revoked', 'R07', 'Authorization Revoked by Customer'),
('BANK001', 'PAY_STOPPED', 'Payment Stopped', 'R08', 'Payment Stopped'),
('BANK001', 'UNCOLL', 'Uncollected Funds', 'R09', 'Uncollected Funds'),
('BANK001', 'NOT_AUTH', 'Not Authorized', 'R10', 'Customer Advises Not Authorized'),
('BANK001', 'STALE', 'Stale Dated', 'R11', 'Check Truncation Entry Return'),
('BANK001', 'POST_DATED', 'Post Dated', 'R12', 'Account Sold to Another DFI'),
('BANK001', 'FROZEN', 'Account Frozen', 'R16', 'Account Frozen'),
('BANK001', 'DUPLICATE', 'Duplicate Return', 'R17', 'File Record Edit Criteria'),
('BANK001', 'AMOUNT_ERR', 'Amount Error', 'R21', 'Invalid Company Identification'),
('BANK001', 'ENDORSEMENT', 'Missing/Irregular Endorsement', 'R25', 'Addenda Error'),
('BANK001', 'ALTER', 'Altered/Fictitious Item', 'R26', 'Mandatory Field Error'),
('BANK001', 'REFER_MAKER', 'Refer to Maker', 'R29', 'Corporate Customer Advises Not Authorized')
ON DUPLICATE KEY UPDATE X9_RETURN_CODE = VALUES(X9_RETURN_CODE), X9_DESCRIPTION = VALUES(X9_DESCRIPTION);

-- ============================================================================
-- SEED: Source Configurations for BANK001
-- ============================================================================

INSERT INTO EIE_SOURCE_CONFIG (BANK_ID, SOURCE_ID, SOURCE_NAME, ACTIVE, CONFIG_JSON) VALUES

-- NSF Returns (Flat File format)
('BANK001', 'POSTING_NSF', 'Posting Engine - NSF Returns', 1, '{
  "sourceId": "POSTING_NSF",
  "sourceName": "Posting Engine - NSF Returns",
  "bankId": "BANK001",
  "fileConfig": {
    "format": "FLAT",
    "encoding": "UTF-8",
    "hasHeader": true,
    "headerLines": 1,
    "hasTrailer": true,
    "trailerLines": 1
  },
  "fieldMapping": {
    "fields": [
      {"name": "transactionId", "start": 1, "end": 20, "type": "string", "trim": true},
      {"name": "payorRT", "start": 21, "end": 29, "type": "string"},
      {"name": "payorAccount", "start": 30, "end": 49, "type": "string", "trim": true},
      {"name": "serialNumber", "start": 50, "end": 64, "type": "string", "trim": true},
      {"name": "amount", "start": 65, "end": 76, "type": "decimal", "impliedDecimals": 2},
      {"name": "returnCode", "start": 77, "end": 80, "type": "string", "trim": true},
      {"name": "returnDate", "start": 81, "end": 88, "type": "date", "format": "yyyyMMdd"},
      {"name": "originalFileId", "start": 89, "end": 100, "type": "long"},
      {"name": "originalItemSeq", "start": 101, "end": 106, "type": "int"}
    ]
  },
  "imageResolution": {
    "mode": "API_LOOKUP",
    "lookupField": "transactionId",
    "dataServicesUrl": "http://accs-data-services:8084",
    "imagePath": "/api/v1/items/{id}/images"
  },
  "s3Config": {
    "inputPrefix": "exception-files/posting-nsf/",
    "processedPrefix": "exception-files/posting-nsf/processed/",
    "failedPrefix": "exception-files/posting-nsf/failed/"
  },
  "batchConfig": {
    "maxItemCount": 100,
    "maxWaitMinutes": 15,
    "groupByDestinationRT": true,
    "maxCashLetterItems": 200
  },
  "x9Config": {
    "originRT": "061000146",
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
    "x9FieldMapping": {
      "returnDetail": {
        "payorBankRoutingNumber": "$payorRT",
        "payorBankCheckDigit": "",
        "onUs": "$payorAccount/$serialNumber",
        "itemAmount": "$amountCents",
        "returnReason": "$x9ReturnCode",
        "eceInstitutionItemSequenceNumber": "$sequenceNumber",
        "returnNotificationIndicator": "1",
        "archiveTypeIndicator": "",
        "addendumCount": 1
      }
    }
  },
  "pollConfig": {
    "intervalSeconds": 30,
    "enabled": true
  }
}'),

-- Stop Payment Returns (CSV format)
('BANK001', 'POSTING_STOP_PAY', 'Posting Engine - Stop Payment Returns', 1, '{
  "sourceId": "POSTING_STOP_PAY",
  "sourceName": "Posting Engine - Stop Payment Returns",
  "bankId": "BANK001",
  "fileConfig": {
    "format": "CSV",
    "encoding": "UTF-8",
    "delimiter": ",",
    "quoteChar": "\\\"",
    "hasHeader": true
  },
  "fieldMapping": {
    "fields": [
      {"name": "transactionId", "column": "TXN_ID", "type": "string"},
      {"name": "payorRT", "column": "ROUTING_NUM", "type": "string"},
      {"name": "payorAccount", "column": "ACCOUNT_NUM", "type": "string"},
      {"name": "serialNumber", "column": "CHECK_NUM", "type": "string"},
      {"name": "amount", "column": "AMOUNT", "type": "decimal"},
      {"name": "returnCode", "column": "REASON_CODE", "type": "string"},
      {"name": "returnDate", "column": "RETURN_DATE", "type": "date", "format": "yyyy-MM-dd"},
      {"name": "frontImageUri", "column": "FRONT_IMG_S3", "type": "string"},
      {"name": "backImageUri", "column": "BACK_IMG_S3", "type": "string"}
    ]
  },
  "imageResolution": {
    "mode": "DIRECT_URI",
    "frontUriField": "frontImageUri",
    "backUriField": "backImageUri"
  },
  "s3Config": {
    "inputPrefix": "exception-files/posting-stop-pay/",
    "processedPrefix": "exception-files/posting-stop-pay/processed/",
    "failedPrefix": "exception-files/posting-stop-pay/failed/"
  },
  "batchConfig": {
    "maxItemCount": 50,
    "maxWaitMinutes": 10,
    "groupByDestinationRT": true,
    "maxCashLetterItems": 100
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "03",
    "maxCashLetterItems": 100,
    "maxItemsPerBundle": 25,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "03", "recordTypeIndicator": "I", "documentationTypeIndicator": "G"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {
      "returnDetail": {
        "payorBankRoutingNumber": "$payorRT",
        "payorBankCheckDigit": "",
        "onUs": "$payorAccount/$serialNumber",
        "itemAmount": "$amountCents",
        "returnReason": "$x9ReturnCode",
        "eceInstitutionItemSequenceNumber": "$sequenceNumber",
        "returnNotificationIndicator": "1",
        "archiveTypeIndicator": "",
        "addendumCount": 1
      }
    }
  },
  "pollConfig": {
    "intervalSeconds": 30,
    "enabled": true
  }
}'),

-- Account Closed Returns (JSON format)
('BANK001', 'POSTING_ACCT_CLOSED', 'Posting Engine - Account Closed Returns', 1, '{
  "sourceId": "POSTING_ACCT_CLOSED",
  "sourceName": "Posting Engine - Account Closed Returns",
  "bankId": "BANK001",
  "fileConfig": {
    "format": "JSON",
    "encoding": "UTF-8",
    "recordsPath": "returns"
  },
  "fieldMapping": {
    "fields": [
      {"name": "transactionId", "jsonPath": "txnId", "type": "string"},
      {"name": "payorRT", "jsonPath": "routingNumber", "type": "string"},
      {"name": "payorAccount", "jsonPath": "accountNumber", "type": "string"},
      {"name": "serialNumber", "jsonPath": "checkSerial", "type": "string"},
      {"name": "amount", "jsonPath": "checkAmount", "type": "decimal"},
      {"name": "returnCode", "jsonPath": "reasonCode", "type": "string"},
      {"name": "returnDate", "jsonPath": "returnDate", "type": "date", "format": "yyyy-MM-dd"},
      {"name": "destinationRT", "jsonPath": "destRoutingNumber", "type": "string"}
    ]
  },
  "imageResolution": {
    "mode": "API_LOOKUP",
    "lookupField": "transactionId",
    "dataServicesUrl": "http://accs-data-services:8084",
    "imagePath": "/api/v1/items/{id}/images"
  },
  "s3Config": {
    "inputPrefix": "exception-files/posting-acct-closed/",
    "processedPrefix": "exception-files/posting-acct-closed/processed/",
    "failedPrefix": "exception-files/posting-acct-closed/failed/"
  },
  "batchConfig": {
    "maxItemCount": 50,
    "maxWaitMinutes": 30,
    "groupByDestinationRT": true,
    "maxCashLetterItems": 100
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "03",
    "maxCashLetterItems": 100,
    "maxItemsPerBundle": 25,
    "fieldDefaults": {
      "fileHeader": {"standardLevel": "03", "testIndicator": "T", "resendIndicator": "N", "countryCode": "US"},
      "cashLetterHeader": {"collectionTypeIndicator": "03", "recordTypeIndicator": "I", "documentationTypeIndicator": "G"},
      "returnDetail": {"returnNotificationIndicator": "1", "archiveTypeIndicator": ""}
    },
    "x9FieldMapping": {
      "returnDetail": {
        "payorBankRoutingNumber": "$payorRT",
        "payorBankCheckDigit": "",
        "onUs": "$payorAccount/$serialNumber",
        "itemAmount": "$amountCents",
        "returnReason": "$x9ReturnCode",
        "eceInstitutionItemSequenceNumber": "$sequenceNumber",
        "returnNotificationIndicator": "1",
        "archiveTypeIndicator": "",
        "addendumCount": 1
      }
    }
  },
  "pollConfig": {
    "intervalSeconds": 60,
    "enabled": true
  }
}')

ON DUPLICATE KEY UPDATE CONFIG_JSON = VALUES(CONFIG_JSON), UPDATED_AT = NOW();
