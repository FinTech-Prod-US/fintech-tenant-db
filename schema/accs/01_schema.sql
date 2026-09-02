-- Accs-Server database schema
-- ${DB_NAME_ACCS} defaults to ${DB_NAME_PRIMARY} when --db-name-accs is not
-- passed to render-db.py.  For a shared deployment (single primary DB) that is
-- correct — Accs-Server connects to DB_NAME_PRIMARY for all its tables.
--
-- Accs-Server table locations:
--   users               → ${DB_NAME_PRIMARY}     (schema/primary/01_schema.sql)
--   BANK_MESSAGING_CONFIG → ${DB_NAME_BUSINESS_RULES} (schema/business_rules/10_bank_messaging_config.sql)
--
-- The cheques table below belongs to the legacy Accs Java service and is
-- retained here for reference.  The current Node.js Accs-Server does not use
-- it; it is safe to skip applying this file if cheques are not needed.

USE ${DB_NAME_ACCS};

-- Accs users table (mirrors primary DB users; only needed when DB_NAME_ACCS
-- is provisioned as a separate database from DB_NAME_PRIMARY)
CREATE TABLE IF NOT EXISTS `users` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(100) NOT NULL,
  `email`      VARCHAR(255) NOT NULL,
  `password`   VARCHAR(255) NOT NULL,
  `role`       ENUM('OPERATOR','AUDITOR','ADMIN') NOT NULL DEFAULT 'OPERATOR',
  `status`     ENUM('ACTIVE','INACTIVE')          NOT NULL DEFAULT 'ACTIVE',
  `created_at` DATETIME(6)  DEFAULT NULL,
  `updated_at` DATETIME(6)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`),
  UNIQUE KEY `uk_users_name`  (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Legacy cheque tracking table (original Accs Java service)
CREATE TABLE IF NOT EXISTS `cheques` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `cheque_number` VARCHAR(255) DEFAULT NULL,
  `account_number`VARCHAR(255) DEFAULT NULL,
  `amount`        DECIMAL(38,2)DEFAULT NULL,
  `bank_name`     VARCHAR(255) DEFAULT NULL,
  `payee_name`    VARCHAR(255) DEFAULT NULL,
  `image_url`     VARCHAR(255) NOT NULL,
  `status`        ENUM('PENDING','PROCESSING','VERIFIED','REJECTED','FLAGGED') NOT NULL,
  `reject_reason` VARCHAR(255) DEFAULT NULL,
  `uploaded_by`   BIGINT       DEFAULT NULL,
  `reviewed_by`   BIGINT       DEFAULT NULL,
  `created_at`    DATETIME(6)  DEFAULT NULL,
  `updated_at`    DATETIME(6)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
