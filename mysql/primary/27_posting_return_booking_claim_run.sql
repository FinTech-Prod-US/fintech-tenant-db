-- ============================================================================
-- SPEC_09 Phase 4: POSTING_RETURN_BOOKING.CLAIM_RUN (idempotent). Run after 20.
-- CLAIM_RUN = the GL file stem (GL_EXTRACT_<businessDate>_<HHmmss>) that names the run's CSV (.csv) and fixed-width
-- (.dat) files in POSTING_EOD_FILES. It is stamped on CLAIMED rows BEFORE any file is written so a crashed run can be
-- finalized or released from the file registry. Re-running changes nothing. Copy: posting V5__posting_return_booking_claim_run.sql
-- ============================================================================
USE ${DB_NAME_PRIMARY};
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='POSTING_RETURN_BOOKING' AND COLUMN_NAME='CLAIM_RUN');
SET @s := IF(@c=0,
 'ALTER TABLE POSTING_RETURN_BOOKING ADD COLUMN CLAIM_RUN VARCHAR(64) NULL COMMENT ''GL file stem of the run that claimed the row; set before output is written''',
 'SELECT ''POSTING_RETURN_BOOKING.CLAIM_RUN exists'' AS result');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='POSTING_RETURN_BOOKING' AND INDEX_NAME='IDX_PRB_CLAIM_RUN');
SET @s := IF(@c=0,
 'ALTER TABLE POSTING_RETURN_BOOKING ADD KEY IDX_PRB_CLAIM_RUN (STATE, CLAIM_RUN)',
 'SELECT ''IDX_PRB_CLAIM_RUN exists'' AS result');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
