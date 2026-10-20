-- ============================================================================
-- PAYMENT_ENRICHED_FIELDS — Per-collection-code enriched column label mapping
-- ============================================================================
-- Maps a collection code + enriched column slot (e.g. ENRICHED_DATA_04) to a
-- human-readable label (e.g. "Account Number"), driving how enriched item data
-- is presented across the pipeline/UI.
--
-- NOTE ON ORDERING: a seed for this table ships separately
-- (08_seed_payment_enriched_fields_outclrdda.sql). This CREATE TABLE must be
-- applied BEFORE that seed. It is defined here (not folded into that seed file)
-- because the seed was authored on the OUTCLRDDA branch while the base table
-- was only ever created ad hoc in the runtime DB — this closes the drift gap.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

CREATE TABLE IF NOT EXISTS `PAYMENT_ENRICHED_FIELDS` (
    `ID`                    BIGINT          NOT NULL AUTO_INCREMENT,
    `COLLECTION_CODE`       VARCHAR(10)     NOT NULL COMMENT 'Collection code this mapping applies to',
    `ENRICHED_COLUMN_LABEL` VARCHAR(30)     NOT NULL COMMENT 'e.g. ENRICHED_DATA_04',
    `ENRICHED_COLUMN_VALUE` VARCHAR(100)    NOT NULL COMMENT 'Human-readable label, e.g. Account Number',
    `CREATED_AT`            TIMESTAMP       NULL     DEFAULT CURRENT_TIMESTAMP,
    `UPDATED_AT`            TIMESTAMP       NULL     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`ID`),
    UNIQUE KEY `idx_pef_collection_label` (`COLLECTION_CODE`, `ENRICHED_COLUMN_LABEL`),
    KEY `idx_pef_collection_code` (`COLLECTION_CODE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'PAYMENT_ENRICHED_FIELDS table provisioned' AS result;
