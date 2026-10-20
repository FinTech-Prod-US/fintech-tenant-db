-- Accs-Server: BANK_MESSAGING_CONFIG
-- Lives in business_rules DB alongside API_AGGREGATOR_CONFIG.
-- Captures external SQS/Kafka/API endpoints that banks/fintechs provide for
-- event distribution from the pipeline.

USE ${DB_NAME_BUSINESS_RULES};

CREATE TABLE IF NOT EXISTS `BANK_MESSAGING_CONFIG` (
  `ConfigID`        INT AUTO_INCREMENT PRIMARY KEY,
  `InstitutionName` VARCHAR(100) NOT NULL,
  `MessagingType`   VARCHAR(20)  NOT NULL COMMENT 'SQS | KAFKA | API',
  `Endpoint`        VARCHAR(500) NOT NULL,
  `AuthType`        VARCHAR(20)  DEFAULT 'NONE',
  `AuthSecretRef`   VARCHAR(200) DEFAULT NULL,
  `Status`          VARCHAR(20)  DEFAULT 'ACTIVE' COMMENT 'ACTIVE | INACTIVE | DEGRADED',
  `CreatedDate`     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `ModifiedDate`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_institution` (`InstitutionName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
