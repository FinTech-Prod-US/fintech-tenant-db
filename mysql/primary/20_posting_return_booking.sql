-- ============================================================================
-- SPEC_09 Phase 4: POSTING_RETURN_BOOKING ledger (idempotent). Copy: posting V4__posting_return_booking.sql
-- ============================================================================
USE ${DB_NAME_PRIMARY};
CREATE TABLE IF NOT EXISTS POSTING_RETURN_BOOKING (
  RETURN_PAYMENT_ID         BIGINT        NOT NULL,   -- the returned item (exception-in: the OUTCLRDDA item; exception-out: the INCLRF/INCLRB item; D7-C: the self-rejected INCLFF item)
  RETURN_KIND               VARCHAR(16)   NOT NULL,   -- EXCEPTION_IN | EXCEPTION_OUT
  COLLECTION_CODE           VARCHAR(10)   NOT NULL,
  STATE                     VARCHAR(12)   NOT NULL DEFAULT 'PENDING_FILE',  -- PENDING_FILE | IN_FILE
  BOOKED_BUSINESS_DATE      CHAR(8)       NOT NULL,   -- posting run date that last booked it (rewritten while PENDING_FILE)
  GL_FILE_ID                BIGINT        NULL,       -- POSTING_EOD_FILES.ID of the GL CSV that carries it; set when STATE flips to IN_FILE
  IN_FILE_AT                TIMESTAMP     NULL,
  AMOUNT                    DECIMAL(15,2) NOT NULL,
  DDA_ACCOUNT               VARCHAR(34)   NOT NULL,
  DDA_SOURCE                VARCHAR(24)   NOT NULL,   -- SELF | PARENT_INCLFF | DEPOSIT_TICKET
  SUSPENSE_GL               VARCHAR(32)   NOT NULL,
  DEPOSIT_KEY               VARCHAR(64)   NULL,
  DEPOSIT_TICKET_PAYMENT_ID BIGINT        NULL,
  ORIG_ITEM_KEY             VARCHAR(160)  NULL,       -- duplicate-return guard (7.4): 'OUT|<depositKey>|<rt>|<acct>|<serial>|<amt>' or 'IN|<parentPid>' / 'IN|SELF|<pid>'
  COLLECTIONS_FLAG          CHAR(1)       NOT NULL DEFAULT 'N',   -- 'Y' = clawback posted unconditionally, collections must review
  ADVICE_STATUS             VARCHAR(12)   NULL,       -- NULL pending | SENT | FAILED | SKIPPED
  ADVICE_ATTEMPTS           INT           NOT NULL DEFAULT 0,
  ADVICE_REFERENCE          VARCHAR(64)   NULL,
  ADVICE_LAST_ERROR         VARCHAR(255)  NULL,
  CREATED_AT                TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UPDATED_AT                TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (RETURN_PAYMENT_ID),
  UNIQUE KEY UQ_PRB_ORIG_ITEM (ORIG_ITEM_KEY),
  KEY IDX_PRB_STATE_DATE (STATE, BOOKED_BUSINESS_DATE),
  KEY IDX_PRB_ADVICE (STATE, RETURN_KIND, ADVICE_STATUS),
  KEY IDX_PRB_COLLECTIONS (COLLECTIONS_FLAG, BOOKED_BUSINESS_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
