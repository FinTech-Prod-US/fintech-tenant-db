-- ============================================================================
-- CUSTOMER_ACCOUNT_MASTER — customer mailing addresses for printed advices.
-- Keyed (RT, AccountNumber) to mirror ALL_ACCOUNT_MASTER, which holds the same
-- accounts but carries no address.
--
-- Consumer: the Customer Advice Engine (CAE), via the data-services endpoint
-- GET /api/v1/customer-account/address. CAE resolves the account from
-- ITEM_DETAILS.ORIG_MICR_ACCOUNT + ORIG_MICR_RT (disambiguated by
-- DEBIT_CREDIT_IND) and joins this table to put a real recipient address,
-- support phone and website on the advice letter. SPEC_13 §6.1 / D4.
--
-- Seed note: the spec's stated purpose for the seed is that "lookups line up
-- with items already seeded". Two groups are therefore seeded:
--   (a) the RT 021001208 / 55512000NN accounts, which are the ones that
--       actually appear on seeded ITEM_DETAILS rows, so an advice fired from
--       the seeded deck resolves to a real address instead of resolved:false;
--   (b) the ALL_ACCOUNT_MASTER anchors named in the spec (John Smith, Acme
--       Corp, Mary Johnson, Wayne Enterprises, Robert Lee, Peter Parker),
--       which carry no items but let the (RT, AccountNumber) join to
--       ALL_ACCOUNT_MASTER be verified directly.
-- Every RT below is present in BANK_MASTER_RT, so the FK holds.
--
-- CustomerServicePhone / BankDomain are deliberately non-routable placeholders
-- for local and dev use. Real tenants must replace them with the bank's own
-- published support number and domain before any advice is mailed.
-- Run against: business_rules (${DB_NAME_BUSINESS_RULES})
-- ============================================================================
USE ${DB_NAME_BUSINESS_RULES};

CREATE TABLE IF NOT EXISTS CUSTOMER_ACCOUNT_MASTER (
  RT                   CHAR(9)      NOT NULL,
  AccountNumber        VARCHAR(20)  NOT NULL,
  CustomerID           VARCHAR(20)  NULL,
  CustomerName         VARCHAR(120) NULL,
  AddressLine1         VARCHAR(120) NULL,
  AddressLine2         VARCHAR(120) NULL,
  City                 VARCHAR(60)  NULL,
  State                CHAR(2)      NULL,
  Zip                  VARCHAR(10)  NULL,
  Country              VARCHAR(2)   NOT NULL DEFAULT 'US',
  CustomerServicePhone VARCHAR(32)  NULL,
  BankDomain           VARCHAR(120) NULL,
  Email                VARCHAR(120) NULL,
  CreatedAt            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (RT, AccountNumber),
  KEY IX_CUSTOMER_ACCOUNT_MASTER_ACCT (AccountNumber),
  CONSTRAINT FK_CUSTOMER_ACCOUNT_MASTER_BANK FOREIGN KEY (RT) REFERENCES BANK_MASTER_RT (RT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- (a) Accounts that carry seeded ITEM_DETAILS rows — these make the advice
--     address lookup actually resolve end to end.
INSERT IGNORE INTO CUSTOMER_ACCOUNT_MASTER
  (RT, AccountNumber, CustomerID, CustomerName, AddressLine1, AddressLine2, City, State, Zip, Country, CustomerServicePhone, BankDomain) VALUES
  ('021001208','5551200000','MCB-0001', 'Customer 001',  '412 Lexington Ave',   'Apt 12C',    'New York',    'NY','10017','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200001','MCB-0002', 'Customer 002',  '88 Greenwich St',     NULL,         'New York',    'NY','10006','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200002','CUST-F003','Carol Forward', '1540 Broadway',       'Suite 410',  'New York',    'NY','10036','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200003','CUST-F004','Dave Forward',  '27 Hudson Yards',     NULL,         'New York',    'NY','10001','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200004','MCB-0005', 'Customer 005',  '310 Flatbush Ave',    'Unit 2',     'Brooklyn',    'NY','11217','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200008','CUST-F005','Eve StopPay',   '755 Northern Blvd',   NULL,         'Great Neck',  'NY','11021','US','1-800-555-0100','www.examplebank.com'),
  ('021001208','5551200012','CUST-F006','Frank StopPay', '96-14 Roosevelt Ave', 'Floor 2',    'Queens',      'NY','11372','US','1-800-555-0100','www.examplebank.com');

-- (b) ALL_ACCOUNT_MASTER anchors named in SPEC_13 §6.1 — no seeded items, but
--     they prove the (RT, AccountNumber) key lines up with ALL_ACCOUNT_MASTER.
INSERT IGNORE INTO CUSTOMER_ACCOUNT_MASTER
  (RT, AccountNumber, CustomerID, CustomerName, AddressLine1, AddressLine2, City, State, Zip, Country, CustomerServicePhone, BankDomain) VALUES
  ('021000089','0012345678','CUST1001','John Smith',       '123 Main St',        NULL,        'Minneapolis','MN','55401','US','1-800-555-0100','www.examplebank.com'),
  ('021000089','0023456789','CUST1002','Acme Corp',        '500 Industrial Way', 'Suite 200', 'Newark',     'NJ','07102','US','1-800-555-0100','www.examplebank.com'),
  ('026009593','1111222233','CUST2001','Mary Johnson',     '77 Oak Avenue',      NULL,        'Charlotte',  'NC','28202','US','1-800-555-0100','www.examplebank.com'),
  ('061000104','7777888899','CUST6001','Wayne Enterprises','1007 Mountain Dr',   'Floor 3',   'Gotham',     'NJ','07030','US','1-800-555-0100','www.examplebank.com'),
  ('122000661','3333444455','CUST3001','Robert Lee',       '42 Market St',       NULL,        'San Jose',   'CA','95113','US','1-800-555-0100','www.examplebank.com'),
  ('011000015','6666777788','CUST5001','Peter Parker',     '20 Ingram St',       'Apt 4B',    'Queens',     'NY','11375','US','1-800-555-0100','www.examplebank.com');

SELECT 'CUSTOMER_ACCOUNT_MASTER ready' AS result;
