-- ============================================================================
-- HOLIDAY_INFO seed — New Year's Day
-- Run against: ${DB_NAME_BUSINESS_RULES} (BRE uses BUSINESS_DATE + IS_ACTIVE)
-- Idempotent on unique BUSINESS_DATE.
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

INSERT IGNORE INTO `HOLIDAY_INFO`
    (`BUSINESS_DATE`, `REASON`, `CREATED_AT`, `UPDATED_AT`, `IS_ACTIVE`)
VALUES
    ('2026-01-01', 'New Year''s Day', NOW(), NOW(), 1);

SELECT 'HOLIDAY_INFO New Year seed applied (business_rules)' AS result;
