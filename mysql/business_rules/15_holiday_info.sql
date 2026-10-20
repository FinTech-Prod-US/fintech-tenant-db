-- ============================================================================
-- HOLIDAY_INFO — BRE PayloadEnrichmentService.lookupHoliday
-- Run against: ${DB_NAME_BUSINESS_RULES}
-- Query: SELECT 1 FROM HOLIDAY_INFO WHERE BUSINESS_DATE = ? AND IS_ACTIVE = 1
-- Local E2E 2026-10-01 failed with: Table 'business_rules.HOLIDAY_INFO' doesn't exist
-- Primary copy (FDE) stays in ${DB_NAME_PRIMARY}; this table is for the BRE pool.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

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

SELECT 'business_rules.HOLIDAY_INFO provisioned' AS result;
