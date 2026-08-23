-- ============================================================================
-- BANK_MASTER_RT — MCB + counterpart banks for routing and enrichment
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

INSERT INTO BANK_MASTER_RT (RT, Name, Description, InclearingFlag, OnUsFlag)
VALUES
  ('026013356', 'Metropolitan Commercial Bank', 'MCB - Pilot Bank, New York NY', 'Y', 'Y'),
  ('021001208', 'Federal Reserve Bank of NY', 'FED - New York NY', 'Y', 'N'),
  ('031000053', 'JPMorgan Chase', 'JPMC - Tampa FL', 'Y', 'N'),
  ('026009593', 'Bank of America', 'BofA - Richmond VA', 'Y', 'N'),
  ('021000089', 'Citibank NA', 'Citi - New Castle DE', 'Y', 'N'),
  ('041000124', 'KeyBank NA', 'KeyBank - Cleveland OH', 'Y', 'N')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), Description = VALUES(Description);
