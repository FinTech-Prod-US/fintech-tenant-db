-- ============================================================================
-- INBOUND_RETURN_CODE_MAPPING — X9 return reason code -> disposition reason
-- Run against: business_rules database.
-- Spec: SPEC_10_returned_deposited_item_pipeline.md (Phase A, §4.6)
--
-- Inbound mirror of the outbound EIE_RETURN_CODE_MAPPING. When a deposited item
-- our customer sent out for clearing is RETURNED to us (INCLRF = Fed, INCLRB =
-- bank via SVPCO), the X9 Type-31 returnReason (single char) is mapped here to a
-- disposition reason the Customer Advice Engine resolves to an ADV-RET-* template.
-- DISPOSITION_REASON values must match the advice engine's DISPOSITION_EVENT_MAP
-- keys so no advice-engine code change is needed to resolve the event.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

CREATE TABLE IF NOT EXISTS INBOUND_RETURN_CODE_MAPPING (
    X9_RETURN_CODE     VARCHAR(2)   NOT NULL COMMENT 'X9 Record 31 returnReason (1 char customer, 2 char admin)',
    DISPOSITION_REASON VARCHAR(32)  NOT NULL COMMENT 'Advice-engine disposition reason key (NSF, ACCOUNT_CLOSED, ...)',
    DESCRIPTION        VARCHAR(255) DEFAULT NULL,
    ACTIVE             CHAR(1)      NOT NULL DEFAULT 'Y',
    EFFECTIVE_DATE     DATE         NOT NULL,
    PRIMARY KEY (X9_RETURN_CODE, EFFECTIVE_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed the common X9 customer return codes. DISPOSITION_REASON must be a key the
-- advice engine's DISPOSITION_EVENT_MAP recognizes (NSF, STOP_PAYMENT,
-- ACCOUNT_CLOSED, ACCOUNT_NOT_FOUND, UNAUTHORIZED, STALE_DATED, REFER_TO_MAKER,
-- DUPLICATE, ALTERED_CHECK, POSITIVE_PAY_MISMATCH).
INSERT INTO INBOUND_RETURN_CODE_MAPPING
  (X9_RETURN_CODE, DISPOSITION_REASON, DESCRIPTION, ACTIVE, EFFECTIVE_DATE)
VALUES
  ('A', 'NSF',               'Insufficient funds',                       'Y', '2026-01-01'),
  ('B', 'NSF',               'Uncollected funds hold',                   'Y', '2026-01-01'),
  ('C', 'STOP_PAYMENT',      'Stop payment',                             'Y', '2026-01-01'),
  ('D', 'ACCOUNT_CLOSED',    'Closed account',                           'Y', '2026-01-01'),
  ('E', 'UNAUTHORIZED',      'Unable to locate account / unauthorized',  'Y', '2026-01-01'),
  ('F', 'REFER_TO_MAKER',    'Refer to maker',                           'Y', '2026-01-01'),
  ('G', 'ACCOUNT_NOT_FOUND', 'Account not found / frozen-blocked',       'Y', '2026-01-01'),
  ('H', 'ALTERED_CHECK',     'Altered or fictitious item / suspected',   'Y', '2026-01-01'),
  ('J', 'STALE_DATED',       'Stale dated',                              'Y', '2026-01-01'),
  ('K', 'DUPLICATE',         'Duplicate presentment',                    'Y', '2026-01-01'),
  ('Q', 'UNAUTHORIZED',      'Not authorized (RCC / RCPO)',              'Y', '2026-01-01')
ON DUPLICATE KEY UPDATE
  DISPOSITION_REASON = VALUES(DISPOSITION_REASON),
  DESCRIPTION        = VALUES(DESCRIPTION),
  ACTIVE             = VALUES(ACTIVE);
