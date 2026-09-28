-- ============================================================================
-- HOLIDAY_INFO — Bank holiday calendar for business-day derivation
-- ============================================================================
-- Drives weekend/holiday roll-forward in the business-day services (FDE
-- ProcessingBusinessDayService and the CDE/BR business-day guards). A date
-- present and active here is a non-processing day.
--
-- Previously this table was created ad hoc in the runtime DB but never
-- provisioned here, so a freshly onboarded tenant lacked it. Adding it closes
-- that schema-drift gap.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

CREATE TABLE IF NOT EXISTS `HOLIDAY_INFO` (
    `HOLIDAY_ID`    INT             NOT NULL AUTO_INCREMENT,
    `BUSINESS_DATE` DATE            NOT NULL COMMENT 'The holiday / non-processing date',
    `REASON`        VARCHAR(255)    NULL     COMMENT 'Human-readable holiday name/reason',
    `CREATED_AT`    TIMESTAMP       NULL     DEFAULT NULL,
    `UPDATED_AT`    TIMESTAMP       NULL     DEFAULT NULL,
    `IS_ACTIVE`     TINYINT(1)      NULL     DEFAULT 1 COMMENT '1 = active holiday, 0 = disabled',
    PRIMARY KEY (`HOLIDAY_ID`),
    UNIQUE KEY `UK_HOLIDAY_INFO_BUSINESS_DATE` (`BUSINESS_DATE`),
    KEY `IDX_HOLIDAY_INFO_ACTIVE_DATE` (`IS_ACTIVE`, `BUSINESS_DATE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'HOLIDAY_INFO table provisioned' AS result;
