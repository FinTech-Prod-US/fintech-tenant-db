-- ============================================================================
-- TAE Engine — Schema + Seed Data
-- Run against: check_payment_platform database
-- ============================================================================

USE ${DB_NAME_PRIMARY};

-- ============================================================================
-- SCHEMA
-- ============================================================================

-- 1. Channel configuration (per bank per channel)
CREATE TABLE IF NOT EXISTS TAE_CHANNEL_CONFIG (
    CONFIG_ID           BIGINT AUTO_INCREMENT PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    CHANNEL_ID          VARCHAR(20) NOT NULL,
    CHANNEL_NAME        VARCHAR(100) NOT NULL,
    ACTIVE              TINYINT(1) NOT NULL DEFAULT 1,
    CONFIG_JSON         JSON NOT NULL,
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_bank_channel (BANK_ID, CHANNEL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Deposit records (one deposit = credit ticket + checks + optional cash)
CREATE TABLE IF NOT EXISTS TAE_DEPOSIT (
    DEPOSIT_ID                  VARCHAR(64) PRIMARY KEY,
    BANK_ID                     VARCHAR(20) NOT NULL,
    CHANNEL_ID                  VARCHAR(20) NOT NULL,
    STATUS                      VARCHAR(20) NOT NULL DEFAULT 'STAGED',
    ACCOUNT_NUMBER              VARCHAR(20) NOT NULL,
    ACCOUNT_TYPE                VARCHAR(10),
    DEPOSIT_DATE                DATE,
    TOTAL_AMOUNT                DECIMAL(12,2) NOT NULL,
    CASH_AMOUNT                 DECIMAL(12,2) DEFAULT 0,
    CHECK_COUNT                 INT NOT NULL DEFAULT 0,
    DEPOSIT_SLIP_NUMBER         VARCHAR(50),
    DEPOSIT_SLIP_MICR_RT        VARCHAR(9),
    DEPOSIT_SLIP_MICR_ACCOUNT   VARCHAR(20),
    DEPOSIT_SLIP_MICR_SERIAL    VARCHAR(10),
    DEPOSIT_TICKET_IMAGE_S3_URI VARCHAR(500),
    CASH_TICKET_IMAGE_S3_URI    VARCHAR(500),
    VIRTUAL_TICKET_GENERATED    TINYINT(1) DEFAULT 0,
    CHANNEL_DATA_JSON           JSON,
    BATCH_ID                    VARCHAR(64),
    CREATED_AT                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tae_dep_status (BANK_ID, CHANNEL_ID, STATUS),
    INDEX idx_tae_dep_batch (BATCH_ID),
    INDEX idx_tae_dep_account (ACCOUNT_NUMBER)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Individual items (checks + cash tickets within a deposit)
CREATE TABLE IF NOT EXISTS TAE_TRANSACTION (
    TRANSACTION_ID      VARCHAR(64) PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    CHANNEL_ID          VARCHAR(20) NOT NULL,
    STATUS              VARCHAR(20) NOT NULL DEFAULT 'STAGED',
    ITEM_TYPE           VARCHAR(20) DEFAULT 'CHECK',
    AMOUNT              DECIMAL(12,2) NOT NULL,
    MICR_RT             VARCHAR(9),
    MICR_ACCOUNT        VARCHAR(20),
    MICR_SERIAL         VARCHAR(10),
    MICR_ONUS           VARCHAR(30),
    MICR_AUXONUS        VARCHAR(30),
    MICR_EPC            VARCHAR(5),
    OCR_MICR_RT         VARCHAR(9),
    OCR_MICR_ACCOUNT    VARCHAR(20),
    OCR_MICR_AMOUNT     DECIMAL(12,2),
    OCR_MICR_SERIAL     VARCHAR(10),
    OCR_MICR_EPC        VARCHAR(5),
    OCR_MICR_AUXONUS    VARCHAR(30),
    FRONT_IMAGE_S3_URI  VARCHAR(500),
    BACK_IMAGE_S3_URI   VARCHAR(500),
    CHANNEL_DATA_JSON   JSON,
    BATCH_ID            VARCHAR(64),
    DEPOSIT_ID          VARCHAR(64),
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tae_txn_status (BANK_ID, CHANNEL_ID, STATUS),
    INDEX idx_tae_txn_batch (BATCH_ID),
    INDEX idx_tae_txn_deposit (DEPOSIT_ID),
    INDEX idx_tae_txn_created (CREATED_AT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Batch tracking (groups of deposits flushed together into one X9 file)
CREATE TABLE IF NOT EXISTS TAE_BATCH (
    BATCH_ID            VARCHAR(64) PRIMARY KEY,
    BANK_ID             VARCHAR(20) NOT NULL,
    CHANNEL_ID          VARCHAR(20) NOT NULL,
    STATUS              VARCHAR(20) NOT NULL DEFAULT 'FLUSHING',
    ITEM_COUNT          INT NOT NULL DEFAULT 0,
    TOTAL_AMOUNT        DECIMAL(14,2) DEFAULT 0,
    CASH_LETTER_COUNT   INT DEFAULT 1,
    X9_FILE_NAME        VARCHAR(200),
    X9_FILE_S3_URI      VARCHAR(500),
    X9_FILE_SIZE_BYTES  BIGINT,
    INGESTION_FILE_ID   BIGINT,
    ERROR_MESSAGE       VARCHAR(1000),
    CREATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tae_batch_status (STATUS),
    INDEX idx_tae_batch_bank_channel (BANK_ID, CHANNEL_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- SEED DATA — 6 Channel Configurations for BANK001
-- ============================================================================

INSERT INTO TAE_CHANNEL_CONFIG (BANK_ID, CHANNEL_ID, CHANNEL_NAME, ACTIVE, CONFIG_JSON) VALUES

-- BRANCH
('BANK001', 'BRANCH', 'Branch Teller Deposit', 1, '{
  "channelId": "BRANCH",
  "channelName": "Branch Teller Deposit",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 10000000.00, "required": true},
      {"field": "cashAmount", "type": "decimal", "min": 0, "required": false},
      {"field": "depositSlipNumber", "type": "string", "required": false},
      {"field": "depositSlipImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 1000000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "ocrMicrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": false},
      {"field": "ocrMicrAccount", "type": "string", "maxLength": 20, "required": false},
      {"field": "ocrMicrAmount", "type": "decimal", "required": false},
      {"field": "ocrMicrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "ocrMicrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "ocrMicrAuxOnus", "type": "string", "maxLength": 30, "required": false}
    ],
    "channelSpecific": [
      {"field": "branchNumber", "type": "string", "required": true},
      {"field": "branchLocation", "type": "string", "required": true},
      {"field": "tellerId", "type": "string", "required": true},
      {"field": "tellerName", "type": "string", "required": false},
      {"field": "depositSlipNumber", "type": "string", "required": false}
    ]
  },
  "batchConfig": {
    "maxItemCount": 50,
    "maxWaitMinutes": 10,
    "maxCashLetterItems": 100,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G",
    "maxDepositsPerBundle": 8
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "branchNumber": "$input.branchNumber",
        "tellerId": "$input.tellerId"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}'),

-- ATM
('BANK001', 'ATM', 'ATM Check Deposit', 1, '{
  "channelId": "ATM",
  "channelName": "ATM Check Deposit",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 10000000.00, "required": true},
      {"field": "cashAmount", "type": "decimal", "min": 0, "required": false},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 1000000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true}
    ],
    "channelSpecific": [
      {"field": "atmId", "type": "string", "required": true},
      {"field": "atmLocation", "type": "string", "required": true},
      {"field": "atmNetwork", "type": "string", "required": false},
      {"field": "cardNumberMasked", "type": "string", "required": false},
      {"field": "transactionSequence", "type": "string", "required": false}
    ]
  },
  "batchConfig": {
    "maxItemCount": 30,
    "maxWaitMinutes": 5,
    "maxCashLetterItems": 50,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G"
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "atmId": "$input.atmId",
        "atmLocation": "$input.atmLocation"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}'),

-- MOBILE
('BANK001', 'MOBILE', 'Mobile Check Deposit', 1, '{
  "channelId": "MOBILE",
  "channelName": "Mobile Check Deposit",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 5000.00, "required": true},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 5000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true}
    ],
    "channelSpecific": [
      {"field": "deviceId", "type": "string", "required": true},
      {"field": "appVersion", "type": "string", "required": true},
      {"field": "geoLatitude", "type": "string", "required": false},
      {"field": "geoLongitude", "type": "string", "required": false},
      {"field": "customerId", "type": "string", "required": true},
      {"field": "sessionId", "type": "string", "required": false}
    ]
  },
  "batchConfig": {
    "maxItemCount": 100,
    "maxWaitMinutes": 15,
    "maxCashLetterItems": 200,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G"
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "deviceId": "$input.deviceId",
        "customerId": "$input.customerId"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}'),

-- RDC (Remote Deposit Capture)
('BANK001', 'RDC', 'Remote Deposit Capture', 1, '{
  "channelId": "RDC",
  "channelName": "Remote Deposit Capture",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 10000000.00, "required": true},
      {"field": "cashAmount", "type": "decimal", "min": 0, "required": false},
      {"field": "depositSlipImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 1000000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true}
    ],
    "channelSpecific": [
      {"field": "rdcDeviceId", "type": "string", "required": true},
      {"field": "rdcLocation", "type": "string", "required": true},
      {"field": "scannerModel", "type": "string", "required": false},
      {"field": "batchId", "type": "string", "required": false},
      {"field": "operatorId", "type": "string", "required": true}
    ]
  },
  "batchConfig": {
    "maxItemCount": 50,
    "maxWaitMinutes": 10,
    "maxCashLetterItems": 100,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G"
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "rdcDeviceId": "$input.rdcDeviceId",
        "operatorId": "$input.operatorId"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}'),

-- LOCKBOX
('BANK001', 'LOCKBOX', 'Lockbox Processing', 1, '{
  "channelId": "LOCKBOX",
  "channelName": "Lockbox Processing",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 50000000.00, "required": true},
      {"field": "cashAmount", "type": "decimal", "min": 0, "required": false},
      {"field": "depositSlipImageBase64", "type": "base64", "maxSizeKB": 500, "required": false},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 10000000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true}
    ],
    "channelSpecific": [
      {"field": "lockboxId", "type": "string", "required": true},
      {"field": "lockboxLocation", "type": "string", "required": true},
      {"field": "processingCenter", "type": "string", "required": false},
      {"field": "remittanceId", "type": "string", "required": false},
      {"field": "payorName", "type": "string", "required": false}
    ]
  },
  "batchConfig": {
    "maxItemCount": 200,
    "maxWaitMinutes": 30,
    "maxCashLetterItems": 500,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G"
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "lockboxId": "$input.lockboxId",
        "lockboxLocation": "$input.lockboxLocation"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}'),

-- CORRESPONDENT
('BANK001', 'CORRESPONDENT', 'Correspondent Bank Deposit', 1, '{
  "channelId": "CORRESPONDENT",
  "channelName": "Correspondent Bank Deposit",
  "bankId": "BANK001",
  "active": true,
  "requestFields": {
    "required": [
      {"field": "bankId", "type": "string"},
      {"field": "channelId", "type": "string"},
      {"field": "depositTicket", "type": "object"}
    ],
    "depositTicketFields": [
      {"field": "accountNumber", "type": "string", "minLength": 4, "maxLength": 17, "required": true},
      {"field": "totalAmount", "type": "decimal", "min": 0.01, "max": 100000000.00, "required": true},
      {"field": "depositSlipImageBase64", "type": "base64", "maxSizeKB": 500, "required": false},
      {"field": "accountType", "type": "string", "required": false},
      {"field": "depositDate", "type": "string", "required": false}
    ],
    "checkFields": [
      {"field": "micrRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "micrAccount", "type": "string", "minLength": 1, "maxLength": 20, "required": true},
      {"field": "micrSerial", "type": "string", "maxLength": 10, "required": false},
      {"field": "micrOnus", "type": "string", "maxLength": 30, "required": true},
      {"field": "micrAuxOnus", "type": "string", "maxLength": 30, "required": false},
      {"field": "micrEpc", "type": "string", "maxLength": 5, "required": false},
      {"field": "amount", "type": "decimal", "min": 0.01, "max": 50000000.00, "required": true},
      {"field": "frontImageBase64", "type": "base64", "maxSizeKB": 500, "required": true},
      {"field": "backImageBase64", "type": "base64", "maxSizeKB": 500, "required": true}
    ],
    "channelSpecific": [
      {"field": "correspondentBankId", "type": "string", "required": true},
      {"field": "correspondentRT", "type": "string", "pattern": "^\\\\d{9}$", "required": true},
      {"field": "correspondentName", "type": "string", "required": true},
      {"field": "referenceNumber", "type": "string", "required": false},
      {"field": "settlementDate", "type": "string", "required": false}
    ]
  },
  "batchConfig": {
    "maxItemCount": 20,
    "maxWaitMinutes": 60,
    "maxCashLetterItems": 50,
    "flushOnIdle": true
  },
  "x9Config": {
    "originRT": "061000146",
    "destinationRT": "021000089",
    "originName": "Wave Money Bank",
    "destinationName": "Federal Reserve",
    "collectionTypeIndicator": "1",
    "fedWorkType": "C",
    "recordType": "I",
    "documentType": "G"
  },
  "responseConfig": {
    "deposit": {
      "deposit": {
        "depositId": "$depositId",
        "transactionId": "$depositId",
        "status": "$status",
        "accountNumber": "$input.depositTicket.accountNumber"
      },
      "channel": {
        "channelId": "$channelId",
        "bankId": "$bankId",
        "correspondentBankId": "$input.correspondentBankId",
        "correspondentName": "$input.correspondentName"
      },
      "summary": {
        "checkCount": "$checkCount",
        "hasCash": "$hasCash",
        "checkTotal": "$computed.checkTotal",
        "checkTransactionIds": "$computed.checkTransactionIds",
        "virtualTicketGenerated": "$virtualTicketGenerated"
      },
      "batch": {
        "batchPosition": "$batchPosition",
        "estimatedFlushTime": "$computed.estimatedFlushTime",
        "estimatedFlushInMinutes": "$computed.estimatedFlushInMinutes"
      },
      "processedAt": "$computed.processedAt"
    },
    "flush": {
      "batch": {
        "batchId": "$batchId",
        "status": "$status"
      },
      "summary": {
        "depositCount": "$depositCount",
        "checkCount": "$checkCount",
        "totalAmount": "$totalAmount"
      },
      "ingestion": {
        "fileId": "$fileId"
      }
    },
    "status": {
      "channel": {
        "bankId": "$bankId",
        "channelId": "$channelId"
      },
      "staging": {
        "depositCount": "$stagedDepositCount",
        "oldestAgeMinutes": "$oldestDepositAgeMinutes",
        "estimatedFlushTime": "$computed.estimatedFlushTime"
      }
    }
  }
}')

ON DUPLICATE KEY UPDATE CONFIG_JSON = VALUES(CONFIG_JSON), UPDATED_AT = NOW();

-- ============================================================================
-- ADD x9FieldDefaults to x9Config for all channels
-- These are moov-io specific fields NOT coming from the API request
-- Configurable per channel per bank — no code changes needed
-- ============================================================================

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(
  CONFIG_JSON,
  '$.x9Config.fieldDefaults',
  CAST('{
    "fileHeader": {
      "standardLevel": "03",
      "testIndicator": "T",
      "resendIndicator": "N",
      "countryCode": "US"
    },
    "cashLetterHeader": {
      "collectionTypeIndicator": "01",
      "recordTypeIndicator": "I",
      "documentationTypeIndicator": "G"
    },
    "bundleHeader": {
      "collectionTypeIndicator": "01"
    },
    "checkDetail": {
      "documentationTypeIndicator": "G",
      "returnAcceptanceIndicator": "0",
      "micrValidIndicator": 1,
      "bofdIndicator": "Y",
      "addendumCount": 0,
      "correctionIndicator": 0,
      "archiveTypeIndicator": ""
    }
  }' AS JSON)
) WHERE BANK_ID = 'BANK001';

-- ============================================================================
-- ADD sqsConfig to each channel for async SQS ingestion
-- Queue URLs are environment-specific (LocalStack shown here)
-- maxConcurrency controls parallel message processing per channel
-- pollIntervalSeconds controls how often the queue is polled
-- ============================================================================

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_BRANCH_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_BRANCH_DEPOSIT_DLQ",
  "maxConcurrency": 10,
  "pollIntervalSeconds": 5,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'BRANCH';

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_ATM_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_ATM_DEPOSIT_DLQ",
  "maxConcurrency": 8,
  "pollIntervalSeconds": 3,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'ATM';

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_MOBILE_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_MOBILE_DEPOSIT_DLQ",
  "maxConcurrency": 15,
  "pollIntervalSeconds": 3,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'MOBILE';

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_RDC_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_RDC_DEPOSIT_DLQ",
  "maxConcurrency": 10,
  "pollIntervalSeconds": 5,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'RDC';

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_LOCKBOX_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_LOCKBOX_DEPOSIT_DLQ",
  "maxConcurrency": 20,
  "pollIntervalSeconds": 5,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'LOCKBOX';

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.sqsConfig', CAST('{
  "queueUrl": "http://accs-localstack:4566/000000000000/TAE_CORRESPONDENT_DEPOSIT",
  "dlqUrl": "http://accs-localstack:4566/000000000000/TAE_CORRESPONDENT_DEPOSIT_DLQ",
  "maxConcurrency": 5,
  "pollIntervalSeconds": 10,
  "maxRetriesBeforeDlq": 3
}' AS JSON)) WHERE BANK_ID = 'BANK001' AND CHANNEL_ID = 'CORRESPONDENT';
  

-- ============================================================================
-- ADD x9FieldMapping to fieldDefaults for config-driven X9 file generation
-- Maps $variable references from TransactionEntity to moov-io X9 fields
-- To add/remap a field: update this JSON in DB — no code changes needed
-- ============================================================================

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON,
  '$.x9Config.fieldDefaults._x9FieldMapping', CAST('{
    "checkDetail": {
      "auxiliaryOnUs": "$micrAuxonus",
      "externalProcessingCode": "$micrEpc",
      "payorBankRoutingNumber": "$micrRT",
      "payorBankCheckDigit": "",
      "onUs": "$micrOnus",
      "itemAmount": "$amountCents",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "documentationTypeIndicator": "G",
      "returnAcceptanceIndicator": "0",
      "micrValidIndicator": 1,
      "bofdIndicator": "Y",
      "addendumCount": 0,
      "correctionIndicator": 0,
      "archiveTypeIndicator": ""
    },
    "cashDetail": {
      "auxiliaryOnUs": "",
      "externalProcessingCode": "",
      "payorBankRoutingNumber": "$originRT",
      "payorBankCheckDigit": "",
      "onUs": "$micrOnus",
      "itemAmount": "$amountCents",
      "eceInstitutionItemSequenceNumber": "$sequenceNumber",
      "documentationTypeIndicator": "G",
      "returnAcceptanceIndicator": "0",
      "micrValidIndicator": 1,
      "bofdIndicator": "Y",
      "addendumCount": 0,
      "correctionIndicator": 0,
      "archiveTypeIndicator": ""
    }
  }' AS JSON)
) WHERE BANK_ID = 'BANK001';

-- ============================================================================
-- ADD maxChecksPerDeposit limit per channel
-- Enforced during validation — rejects deposits exceeding the limit
-- BRANCH/ATM/MOBILE: lower limits (API with base64 images)
-- RDC/LOCKBOX/CORRESPONDENT: higher limits (SQS with S3 URIs)
-- ============================================================================

UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 10) WHERE BANK_ID='BANK001' AND CHANNEL_ID='BRANCH';
UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 5) WHERE BANK_ID='BANK001' AND CHANNEL_ID='ATM';
UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 5) WHERE BANK_ID='BANK001' AND CHANNEL_ID='MOBILE';
UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 50) WHERE BANK_ID='BANK001' AND CHANNEL_ID='RDC';
UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 200) WHERE BANK_ID='BANK001' AND CHANNEL_ID='LOCKBOX';
UPDATE TAE_CHANNEL_CONFIG SET CONFIG_JSON = JSON_SET(CONFIG_JSON, '$.requestFields.maxChecksPerDeposit', 100) WHERE BANK_ID='BANK001' AND CHANNEL_ID='CORRESPONDENT';
