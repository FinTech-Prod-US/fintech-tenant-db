-- ============================================================================
-- ITEM_IMAGE_REF — Per-item S3 image reference (SPEC_14, research archive)
-- ============================================================================
-- Data-ingestion writes one row per item image side when it uploads the image
-- to S3 (best-effort, additive: the IMAGE_DATA blob write and the blob-based
-- resolve-image path are unchanged). The Research-Archive-Engine copies these
-- rows into ARCHIVE_ITEM_IMAGE_REF so the archive carries S3 references only.
--
-- S3 key layout: items/<businessDate>/<collectionGroup>/<paymentId>-<seq>-<front|back>.tiff
--
-- PK includes SIDE (SPEC_14 6.1 lists PK as PAYMENT_ID + IMAGE_SEQ_NUM, but a
-- front and a back image for the same sequence number would collide on that key).
-- No FOREIGN KEY on purpose: the upload is best-effort and must never block or
-- fail ingestion.
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================
USE ${DB_NAME_PRIMARY};

CREATE TABLE IF NOT EXISTS `ITEM_IMAGE_REF` (
    `PAYMENT_ID`     BIGINT          NOT NULL COMMENT 'ITEM_DETAILS.PAYMENT_ID',
    `IMAGE_SEQ_NUM`  BIGINT          NOT NULL COMMENT 'Matches IMAGE_DATA.IMAGE_SEQ_NUM',
    `SIDE`           ENUM('FRONT','BACK') NOT NULL,
    `S3_BUCKET`      VARCHAR(120)    NOT NULL,
    `S3_KEY`         VARCHAR(400)    NOT NULL,
    `CONTENT_TYPE`   VARCHAR(40)     NULL     COMMENT 'e.g. image/tiff',
    `UPLOADED_AT`    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`PAYMENT_ID`, `IMAGE_SEQ_NUM`, `SIDE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'ITEM_IMAGE_REF table provisioned' AS result;
