-- ============================================================================
-- PAYMENT_SEQUENCE_COUNTER — Per-day / source / worktype / device sequence
-- ============================================================================
-- Supplies the monotonic sequence used when minting payment identifiers during
-- ingestion/enrichment, scoped by business date + source code + worktype +
-- device. One row per (business_date, source_code, worktype_code, device_id);
-- current_sequence is advanced as items are assigned.
--
-- Previously created ad hoc in the runtime DB but not provisioned here — added
-- to close the schema-drift gap.
-- ============================================================================
USE ${DB_NAME_PRIMARY};

CREATE TABLE IF NOT EXISTS `PAYMENT_SEQUENCE_COUNTER` (
    `business_date`    DATE        NOT NULL COMMENT 'Business date the counter belongs to',
    `source_code`      CHAR(2)     NOT NULL COMMENT 'Source code (2 char)',
    `worktype_code`    CHAR(3)     NOT NULL COMMENT 'Work type code (3 char)',
    `device_id`        CHAR(3)     NOT NULL COMMENT 'Device id (3 char)',
    `current_sequence` INT         NOT NULL COMMENT 'Last-issued sequence value for this scope',
    `updated_at`       TIMESTAMP   NOT NULL COMMENT 'When the counter was last advanced',
    PRIMARY KEY (`business_date`, `source_code`, `worktype_code`, `device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'PAYMENT_SEQUENCE_COUNTER table provisioned' AS result;
