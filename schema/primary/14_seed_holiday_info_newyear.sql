-- ============================================================================
-- HOLIDAY_INFO seed — New Year's Day
-- Run against: ${DB_NAME_PRIMARY} (FDE uses HOLIDAY_DATE + IS_ACTIVE)
-- Idempotent on unique BUSINESS_DATE.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

INSERT IGNORE INTO `HOLIDAY_INFO`
    (`BUSINESS_DATE`, `HOLIDAY_DATE`, `REASON`, `CREATED_AT`, `UPDATED_AT`, `IS_ACTIVE`)
VALUES
    ('2026-01-01', '2026-01-01', 'New Year''s Day', NOW(), NOW(), 1);

SELECT 'HOLIDAY_INFO New Year seed applied (primary)' AS result;
