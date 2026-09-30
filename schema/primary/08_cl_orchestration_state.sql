-- ============================================================================
-- CL_ORCHESTRATION_STATE — durable endpoint-resolution completion barrier
-- ============================================================================
-- Backs the CDE endpoint-resolution / CashLetter-build barrier. Replaces CDE's
-- former in-memory guard (a JVM Set) with durable DB state keyed by CASHLTR_ID,
-- so the "resolve endpoints once" decision survives CDE restarts, is shared
-- across CDE instances, and resets when the row is cleaned up (a reused
-- CASHLTR_ID is no longer permanently blocked).
--
-- Atomic claim (run by data-services): INSERT IGNORE a PENDING row, then
--   UPDATE ... SET ENDPOINT_RESOLUTION_STATUS='IN_PROGRESS'
--   WHERE CASHLTR_ID=? AND ENDPOINT_RESOLUTION_STATUS='PENDING'
-- Exactly one caller sees affectedRows=1.
--
-- Provisioned here (tenant onboarding) so new tenants get it from day one;
-- data-services also ships a runtime create script.
-- ============================================================================

USE ${DB_NAME_PRIMARY};

CREATE TABLE IF NOT EXISTS `CL_ORCHESTRATION_STATE` (
    `CASHLTR_ID`                 BIGINT       NOT NULL COMMENT 'FK to CASH_LETTER_DETAILS.CASHLTR_ID (durable barrier key)',
    `ENDPOINT_RESOLUTION_STATUS` VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING | IN_PROGRESS | COMPLETED | FAILED',
    `BUILD_REQUEST_ID`           VARCHAR(100) NULL     COMMENT 'CashLetter build request id issued once resolution is claimed',
    `CLAIMED_AT`                 TIMESTAMP    NULL     COMMENT 'When endpoint resolution was claimed (PENDING->IN_PROGRESS)',
    `COMPLETED_AT`               TIMESTAMP    NULL     COMMENT 'When endpoint resolution + build completed',
    `CREATED_AT`                 TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `UPDATED_AT`                 TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`CASHLTR_ID`),
    INDEX `idx_clos_status` (`ENDPOINT_RESOLUTION_STATUS`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
