-- WITHDRAWN.
-- Per-code UPDATE of source_code/work_type was not applied: it is not INSERT IGNORE,
-- not scalable, and would rewrite live MICR rows on Jenkins re-apply.
-- Unique key for INSERT IGNORE lives in 11_micr_unique_coll.sql.
-- Seed values stay in 02_seed.sql / 06_seed_tae_eie.sql INSERT IGNORE rows.

SELECT '11_micr_source_work_mandatory withdrawn — no data change' AS result;
