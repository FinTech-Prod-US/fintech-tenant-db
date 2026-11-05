-- ============================================================================
-- SPEC_09 Phase 1 — posting-time balanced double-entry GL booking.
-- CREDIT_POSTING_RULE + the three GL reference tables the Posting-EOD engine
-- reads to resolve the credit/debit side of every settlement unit:
--   CREDIT_POSTING_RULE  — per collection code: balancing unit granularity and
--                          how each side's account is resolved.
--   SETTLEMENT_GL_REF    — Fed settlement GL by sending institution RT ('*' = default).
--   FLOAT_CLEARING_GL    — deposit float / outclearing clearing GL.
--   RETURN_SUSPENSE_GL   — return suspense GL by direction (IN / OUT).
--
-- GL strings use new category blocks (210=settlement, 220=float/clearing,
-- 230=return suspense) so they do not collide with the existing 1XX / 100X
-- blocks already seeded in POSTING_CODE_REF (business_rules/02_seed.sql).
--
-- !! The GL accounts and the sending RT seeded below are ILLUSTRATIVE
-- !! PLACEHOLDERS (SPEC_09 §12.4). Real GL/RT values are supplied by the
-- !! product owner before the sandbox apply. Before applying, enumerate the
-- !! real settlement RTs with:
-- !!   SELECT DISTINCT ORIG_RT FROM INBOUND_FILE_DETAILS WHERE ORIG_RT IS NOT NULL;
-- !! and add one SETTLEMENT_GL_REF row per Fed-forward RT (keep the '*' row).
--
-- The two RETURN rules are seeded for completeness only — Phase 1 code does NOT
-- book returns (deferred to Phase 4, which needs the SPEC_09 §15 depositor linkage).
--
-- Run against: business_rules (${DB_NAME_BUSINESS_RULES})
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

-- ── CREDIT_POSTING_RULE ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS CREDIT_POSTING_RULE (
  COLLECTION_CODE           VARCHAR(20)  NOT NULL,  -- INCLFF, OUTCL*, INCLEARING_RETURN, OUTCLEARING_RETURN
  GRANULARITY               VARCHAR(16)  NOT NULL,  -- PER_CASH_LETTER | PER_DEPOSIT | PER_ITEM
  CREDIT_SIDE               VARCHAR(4)   NOT NULL,  -- GL | DDA
  CREDIT_ACCOUNT_RESOLUTION VARCHAR(40)  NOT NULL,  -- FIXED_GL | BY_SENDING_INSTITUTION_RT | DDA_FROM_ITEM | DDA_FROM_ORIGINAL_DEPOSIT | RETURN_SUSPENSE
  CREDIT_CARRIER            VARCHAR(16)  NULL,      -- CL_HEADER | LEADING_ITEM | NULL
  DEBIT_SIDE                VARCHAR(4)   NOT NULL,  -- DDA | GL
  DEBIT_ACCOUNT_RESOLUTION  VARCHAR(40)  NOT NULL,  -- DDA_EFFECTIVE | FLOAT_CLEARING_GL | RETURN_SUSPENSE | DDA_FROM_ORIGINAL_DEPOSIT
  BOOKED_AT                 VARCHAR(20)  NOT NULL,  -- POSTING | CL_BUILD+POSTING
  INVARIANT                 VARCHAR(64)  NOT NULL,  -- 'SUM_DEBIT_EQ_CREDIT'
  Active                    CHAR(1)      NOT NULL DEFAULT 'Y',
  EffectiveDate             DATE         NOT NULL DEFAULT (curdate()),
  PRIMARY KEY (COLLECTION_CODE, EffectiveDate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── SETTLEMENT_GL_REF ────────────────────────────────────────────────────────
-- NOTE: SendingRT is CHAR(9) to match POSTING_CODE_REF.RT, but
-- INBOUND_FILE_DETAILS.ORIG_RT is char(20) — the engine MUST join on
-- TRIM(f.ORIG_RT) = SendingRT (see CreditPostingRuleService.resolveSettlementGl).
CREATE TABLE IF NOT EXISTS SETTLEMENT_GL_REF (
  SendingRT     CHAR(9)      NOT NULL,   -- '*' for the default fallback row
  GLAccount     VARCHAR(32)  NOT NULL,   -- e.g. '210-SET-01'
  Description   VARCHAR(255),
  Active        CHAR(1)      NOT NULL DEFAULT 'Y',
  EffectiveDate DATE         NOT NULL,
  PRIMARY KEY (SendingRT, EffectiveDate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── FLOAT_CLEARING_GL ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS FLOAT_CLEARING_GL (
  Channel       VARCHAR(32)  NULL,       -- NULL = applies to all channels
  GLAccount     VARCHAR(32)  NOT NULL,   -- e.g. '220-FLT-01'
  Description   VARCHAR(255),
  Active        CHAR(1)      NOT NULL DEFAULT 'Y',
  EffectiveDate DATE         NOT NULL,
  PRIMARY KEY (GLAccount, EffectiveDate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── RETURN_SUSPENSE_GL ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS RETURN_SUSPENSE_GL (
  Direction     CHAR(3)      NOT NULL,   -- 'IN' (inclearing return) | 'OUT' (outclearing return)
  GLAccount     VARCHAR(32)  NOT NULL,   -- e.g. '230-SUS-IN' / '230-SUS-OUT'
  Description   VARCHAR(255),
  Active        CHAR(1)      NOT NULL DEFAULT 'Y',
  EffectiveDate DATE         NOT NULL,
  PRIMARY KEY (Direction, EffectiveDate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── SEEDS (SPEC_09 §12.4 — ILLUSTRATIVE) ─────────────────────────────────────
-- CREDIT_POSTING_RULE: INCLFF + one outclearing-forward row + the two return rows.
-- Add one OUTCL* row per outclearing channel actually present for the tenant
-- (COLLECTION_CODE_GROUP.GROUP_NAME='OUTCLEARING' enumerates the candidates).
-- EffectiveDate defaults to CURDATE() per SPEC_09 §12.4; the engine always takes
-- the newest Active row (ORDER BY EffectiveDate DESC LIMIT 1), so re-applying on a
-- later date adds a new effective-dated row rather than changing resolution.
INSERT INTO CREDIT_POSTING_RULE
  (COLLECTION_CODE, GRANULARITY, CREDIT_SIDE, CREDIT_ACCOUNT_RESOLUTION, CREDIT_CARRIER,
   DEBIT_SIDE, DEBIT_ACCOUNT_RESOLUTION, BOOKED_AT, INVARIANT, Active, EffectiveDate) VALUES
  ('INCLFF','PER_CASH_LETTER','GL','BY_SENDING_INSTITUTION_RT','CL_HEADER','DDA','DDA_EFFECTIVE','POSTING','SUM_DEBIT_EQ_CREDIT','Y',CURDATE()),
  ('OUTCLFBR','PER_DEPOSIT','DDA','DDA_FROM_ITEM','LEADING_ITEM','GL','FLOAT_CLEARING_GL','POSTING','SUM_DEBIT_EQ_CREDIT','Y',CURDATE()),
  ('INCLEARING_RETURN','PER_ITEM','DDA','DDA_EFFECTIVE',NULL,'GL','RETURN_SUSPENSE','POSTING','SUM_DEBIT_EQ_CREDIT','Y',CURDATE()),
  ('OUTCLEARING_RETURN','PER_ITEM','GL','RETURN_SUSPENSE',NULL,'DDA','DDA_FROM_ORIGINAL_DEPOSIT','POSTING','SUM_DEBIT_EQ_CREDIT','Y',CURDATE())
ON DUPLICATE KEY UPDATE
  GRANULARITY=VALUES(GRANULARITY), CREDIT_SIDE=VALUES(CREDIT_SIDE),
  CREDIT_ACCOUNT_RESOLUTION=VALUES(CREDIT_ACCOUNT_RESOLUTION), CREDIT_CARRIER=VALUES(CREDIT_CARRIER),
  DEBIT_SIDE=VALUES(DEBIT_SIDE), DEBIT_ACCOUNT_RESOLUTION=VALUES(DEBIT_ACCOUNT_RESOLUTION),
  BOOKED_AT=VALUES(BOOKED_AT), INVARIANT=VALUES(INVARIANT), Active='Y';

-- SETTLEMENT_GL_REF: illustrative Fed-forward RT + the mandatory '*' default row.
INSERT INTO SETTLEMENT_GL_REF (SendingRT, GLAccount, Description, Active, EffectiveDate) VALUES
  ('021001208', '210-SET-01', 'Fed settlement - sending RT 021001208', 'Y', '2026-01-01'),
  ('*',         '210-SET-99', 'Fed settlement - default/fallback',     'Y', '2026-01-01')
ON DUPLICATE KEY UPDATE
  GLAccount=VALUES(GLAccount), Description=VALUES(Description), Active='Y';

INSERT INTO FLOAT_CLEARING_GL (Channel, GLAccount, Description, Active, EffectiveDate) VALUES
  (NULL, '220-FLT-01', 'Deposit float / outclearing clearing GL (all channels)', 'Y', '2026-01-01')
ON DUPLICATE KEY UPDATE
  Channel=VALUES(Channel), Description=VALUES(Description), Active='Y';

INSERT INTO RETURN_SUSPENSE_GL (Direction, GLAccount, Description, Active, EffectiveDate) VALUES
  ('IN',  '230-SUS-IN',  'Return suspense - inclearing returns',  'Y', '2026-01-01'),
  ('OUT', '230-SUS-OUT', 'Return suspense - outclearing returns', 'Y', '2026-01-01')
ON DUPLICATE KEY UPDATE
  GLAccount=VALUES(GLAccount), Description=VALUES(Description), Active='Y';

SELECT 'CREDIT_POSTING_RULE + GL reference tables ready' AS result;
