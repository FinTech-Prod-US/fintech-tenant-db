-- ============================================================================
-- SPEC_09 Phase 4: POSTING_GL_RUN run-id reservation (idempotent). Run after 27.
-- A GL run reserves its id with a single INSERT (RUN_ID primary key) BEFORE any return claim is stamped or any file
-- is written; a duplicate key means another run owns the id. RUN_ID = <businessDate>-<UTC yyyyMMddHHmmssSSS>-<8 hex>,
-- and names the files GL_EXTRACT_<RUN_ID>.csv / .dat. Makes the run identity safe across Posting instances.
-- Copy: posting V6__posting_gl_run.sql
-- ============================================================================
USE ${DB_NAME_PRIMARY};
CREATE TABLE IF NOT EXISTS POSTING_GL_RUN (
  RUN_ID        VARCHAR(48) NOT NULL,
  BUSINESS_DATE CHAR(8)     NOT NULL,
  CREATED_AT    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (RUN_ID),
  KEY IDX_PGR_DATE (BUSINESS_DATE)
) ENGINE=InnoDB;
