-- ============================================================================
-- ENDPOINT_DIRECTION_RULES — Configurable forward/return direction logic
-- Determines whether an item goes FORWARD (clearing) or RETURN (back to sender)
-- based on collection code and BR exception code
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

CREATE TABLE IF NOT EXISTS ENDPOINT_DIRECTION_RULES (
    RULE_ID         INT AUTO_INCREMENT PRIMARY KEY,
    COLLECTION_CODE VARCHAR(20) NOT NULL,
    EXCEPTION_PATTERN VARCHAR(50) DEFAULT NULL COMMENT 'NULL = no exception (item passed). * = catch-all. Specific = exact match.',
    DIRECTION       VARCHAR(10) NOT NULL COMMENT 'FORWARD or RETURN',
    PRIORITY        INT NOT NULL DEFAULT 100 COMMENT 'Lower number = higher priority',
    DESCRIPTION     VARCHAR(255) DEFAULT NULL,
    ACTIVE          TINYINT(1) NOT NULL DEFAULT 1,
    CREATED_AT      DATETIME DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_edr_lookup (COLLECTION_CODE, ACTIVE, PRIORITY)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- Seed: INCLFF (Inclearing Forward Fed)
-- Items with no exception → FORWARD
-- Items with any BR exception → RETURN
-- ============================================================================

INSERT IGNORE INTO ENDPOINT_DIRECTION_RULES (COLLECTION_CODE, EXCEPTION_PATTERN, DIRECTION, PRIORITY, DESCRIPTION) VALUES
-- No exception = item passed all BR checks → FORWARD to clearing
('INCLFF', NULL, 'FORWARD', 100, 'INCLFF: Items with no exception go FORWARD to FED for clearing'),
-- Specific exceptions → RETURN
('INCLFF', 'ACCOUNT_NOT_FOUND', 'RETURN', 50, 'INCLFF: Account not found → RETURN to originator'),
('INCLFF', 'ACCOUNT_CLOSED', 'RETURN', 50, 'INCLFF: Account closed → RETURN'),
('INCLFF', 'ACCOUNT_FROZEN', 'RETURN', 50, 'INCLFF: Account frozen → RETURN'),
('INCLFF', 'STOP_PAY_RETURN', 'RETURN', 50, 'INCLFF: Stop payment → RETURN'),
('INCLFF', 'POSITIVE_PAY_RETURN', 'RETURN', 50, 'INCLFF: Positive pay mismatch → RETURN'),
('INCLFF', 'COUNTERFEIT_SUSPECTED', 'RETURN', 50, 'INCLFF: Fraud/counterfeit → RETURN'),
('INCLFF', 'ENRICHMENT_ERROR', 'RETURN', 50, 'INCLFF: BR enrichment error → RETURN'),
('INCLFF', 'NOT_OUR_ITEM', 'RETURN', 50, 'INCLFF: Not our item → RETURN'),
('INCLFF', 'EXCEED_ITEM_LIMIT', 'RETURN', 50, 'INCLFF: Exceeds deposit limit → RETURN'),
('INCLFF', 'STALE_DATED', 'RETURN', 50, 'INCLFF: Stale dated check → RETURN'),
('INCLFF', '*', 'RETURN', 200, 'INCLFF: Catch-all — any unmatched exception → RETURN'),

-- INCLFB (same rules as INCLFF for now)
('INCLFB', NULL, 'FORWARD', 100, 'INCLFB: Items with no exception go FORWARD'),
('INCLFB', '*', 'RETURN', 200, 'INCLFB: Any exception → RETURN'),

-- INCLRF (Inclearing Return Fed) — all items go FORWARD (returns are being forwarded to destination)
('INCLRF', NULL, 'FORWARD', 100, 'INCLRF: Return items forwarded to destination'),
('INCLRF', '*', 'FORWARD', 200, 'INCLRF: All returns go FORWARD'),

-- INCLRB (same as INCLRF)
('INCLRB', NULL, 'FORWARD', 100, 'INCLRB: Return items forwarded to destination'),
('INCLRB', '*', 'FORWARD', 200, 'INCLRB: All returns go FORWARD'),

-- POD channels — all go FORWARD (outclearing)
('OUTCLFBR', NULL, 'FORWARD', 100, 'POD Branch: All items FORWARD'),
('OUTCLFBR', '*', 'FORWARD', 200, 'POD Branch: Even exceptions go FORWARD for clearing'),
('OUTCLFATM', NULL, 'FORWARD', 100, 'POD ATM: All items FORWARD'),
('OUTCLFATM', '*', 'FORWARD', 200, 'POD ATM: All FORWARD'),
('OUTCLFMOB', NULL, 'FORWARD', 100, 'POD Mobile: All items FORWARD'),
('OUTCLFMOB', '*', 'FORWARD', 200, 'POD Mobile: All FORWARD'),
('OUTCLFRDC', NULL, 'FORWARD', 100, 'POD RDC: All items FORWARD'),
('OUTCLFRDC', '*', 'FORWARD', 200, 'POD RDC: All FORWARD'),
('OUTCLFLBX', NULL, 'FORWARD', 100, 'POD Lockbox: All items FORWARD'),
('OUTCLFLBX', '*', 'FORWARD', 200, 'POD Lockbox: All FORWARD'),
('OUTCLFCOR', NULL, 'FORWARD', 100, 'POD Correspondent: All items FORWARD'),
('OUTCLFCOR', '*', 'FORWARD', 200, 'POD Correspondent: All FORWARD'),

-- Outgoing Returns — all go FORWARD (returns being sent out)
('OUTCLRDDA', NULL, 'FORWARD', 100, 'Outgoing Return DDA: All FORWARD'),
('OUTCLRDDA', '*', 'FORWARD', 200, 'Outgoing Return DDA: All FORWARD'),
('OUTCLRCD', NULL, 'FORWARD', 100, 'Outgoing Return Card: All FORWARD'),
('OUTCLRCD', '*', 'FORWARD', 200, 'Outgoing Return Card: All FORWARD'),
('OUTCLRLN', NULL, 'FORWARD', 100, 'Outgoing Return Loan: All FORWARD'),
('OUTCLRLN', '*', 'FORWARD', 200, 'Outgoing Return Loan: All FORWARD')
ON DUPLICATE KEY UPDATE DIRECTION = VALUES(DIRECTION);
