-- WITHDRAWN for this slice.
-- Changing BUSINESS_DAY PK and dropping ITEM_DETAILS.BDAY_ID FK is a live-data
-- risk. Do not run on Jenkins or local re-apply until explicitly approved.
-- Original ALTER is kept out of apply-db by this no-op.

SELECT '07_business_day_category withdrawn — no schema change' AS result;
