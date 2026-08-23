-- ============================================================================
-- Business Rules Seed Data for ALL Collection Codes
-- Inclearing (INCLFF, INCLFB, INCLRF, INCLRB) + TAE (POD) + EIE (Outgoing Returns)
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

-- ============================================================================
-- INCLEARING — Forward & Return Presentment (files received from FED/Banks)
-- Coll_Type = 01 (Forward), 02 (Return)
-- ============================================================================

-- COLLECTION_CODE_ORIGRT_REF — maps Origin RT → Collection Code for inclearing
INSERT IGNORE INTO COLLECTION_CODE_ORIGRT_REF (Coll_Type, OriginRT, Collection_Code, Description) VALUES
('01', '021001208', 'INCLFF',  'Inclearing file from FED - Forward Presentment'),
('01', '031000053', 'INCLFF',  'Inclearing file from JPMorgan Chase - Forward Presentment'),
('01', '026009593', 'INCLFF',  'Inclearing file from Bank of America - Forward Presentment'),
('01', '021000089', 'INCLFB',  'Inclearing file from Citibank - Forward Presentment (Bank)'),
('01', '041000124', 'INCLFB',  'Inclearing file from KeyBank - Forward Presentment (Bank)'),
('02', '021001208', 'INCLRF',  'Inclearing file from FED - Return Presentment'),
('02', '031000053', 'INCLRF',  'Inclearing file from JPMorgan Chase - Return Presentment'),
('02', '026009593', 'INCLRF',  'Inclearing file from Bank of America - Return Presentment'),
('02', '021000089', 'INCLRB',  'Inclearing file from Citibank - Return Presentment (Bank)'),
('02', '041000124', 'INCLRB',  'Inclearing file from KeyBank - Return Presentment (Bank)');

-- COLLECTION_CODE_MICR — BIN range assignments for inclearing
INSERT IGNORE INTO COLLECTION_CODE_MICR (Coll_Type, Coll_Code, `Bin#Start`, `Bin#End`, BatchStart, BatchEnd, FileDeadline, Description) VALUES
('01', 'INCLFF',  1,    1000, 1, 1000, '17:00:00', 'FED Forward Presentment - Bin Range 0001-1000, 5PM Deadline'),
('01', 'INCLFB',  1001, 2000, 1, 1000, '22:00:00', 'Bank Forward Presentment - Bin Range 1001-2000, 10PM Deadline'),
('02', 'INCLRF',  2001, 3000, 1, 1000, NULL,       'FED Return Presentment - Bin Range 2001-3000, No Deadline'),
('02', 'INCLRB',  3001, 4000, 1, 1000, NULL,       'Bank Return Presentment - Bin Range 3001-4000, No Deadline');

-- COLLECTION_CODE_UD_REF — UserField/FedWorkType mapping for inclearing
INSERT IGNORE INTO COLLECTION_CODE_UD_REF (Coll_Type, OriginRT, UserField, FedWorkType, Coll_Code, Description) VALUES
('01', '021001208', '', 'C', 'INCLFF',  'Inclearing FED Forward - (FedWorkType C)'),
('01', '031000053', '', 'C', 'INCLFF',  'Inclearing JPMorgan Forward - (FedWorkType C)'),
('01', '026009593', '', 'C', 'INCLFF',  'Inclearing BofA Forward - (FedWorkType C)'),
('01', '021000089', '', 'C', 'INCLFB',  'Inclearing Citibank Forward - (FedWorkType C)'),
('01', '041000124', '', 'C', 'INCLFB',  'Inclearing KeyBank Forward - (FedWorkType C)'),
('02', '021001208', '', 'C', 'INCLRF',  'Inclearing FED Return - (FedWorkType C)'),
('02', '031000053', '', 'C', 'INCLRF',  'Inclearing JPMorgan Return - (FedWorkType C)'),
('02', '026009593', '', 'C', 'INCLRF',  'Inclearing BofA Return - (FedWorkType C)'),
('02', '021000089', '', 'C', 'INCLRB',  'Inclearing Citibank Return - (FedWorkType C)'),
('02', '041000124', '', 'C', 'INCLRB',  'Inclearing KeyBank Return - (FedWorkType C)');

-- ============================================================================
-- TAE Engine — POD (Point of Deposit) Forward Presentment
-- Coll_Type = 01 (Forward), unique Origin RT per channel
-- ============================================================================

-- COLLECTION_CODE_ORIGRT_REF — maps Origin RT → Collection Code
INSERT IGNORE INTO COLLECTION_CODE_ORIGRT_REF (Coll_Type, OriginRT, Collection_Code, Description) VALUES
('01', '061000140', 'OUTCLFBR',  'POD - Branch Teller Deposit (Forward to FED)'),
('01', '061000141', 'OUTCLFATM', 'POD - ATM Check Deposit (Forward to FED)'),
('01', '061000142', 'OUTCLFMOB', 'POD - Mobile Check Deposit (Forward to FED)'),
('01', '061000143', 'OUTCLFRDC', 'POD - Remote Deposit Capture (Forward to FED)'),
('01', '061000144', 'OUTCLFLBX', 'POD - Lockbox Deposit (Forward to FED)'),
('01', '061000145', 'OUTCLFCOR', 'POD - Correspondent Bank Deposit (Forward to FED)');

-- COLLECTION_CODE_MICR — BIN range assignments per POD channel
-- Note: source_code and work_type columns are added separately (ALTER TABLE) for local dev
INSERT IGNORE INTO COLLECTION_CODE_MICR (Coll_Type, Coll_Code, `Bin#Start`, `Bin#End`, BatchStart, BatchEnd, FileDeadline, Description) VALUES
('01', 'OUTCLFBR',  4001, 5000, 1, 1000, '17:00:00', 'POD Branch - Bin 4001-5000, 5PM Deadline'),
('01', 'OUTCLFATM', 5001, 6000, 1, 1000, '20:00:00', 'POD ATM - Bin 5001-6000, 8PM Deadline'),
('01', 'OUTCLFMOB', 6001, 7000, 1, 1000, '22:00:00', 'POD Mobile - Bin 6001-7000, 10PM Deadline'),
('01', 'OUTCLFRDC', 7001, 8000, 1, 1000, '17:00:00', 'POD RDC - Bin 7001-8000, 5PM Deadline'),
('01', 'OUTCLFLBX', 8001, 9000, 1, 1000, '15:00:00', 'POD Lockbox - Bin 8001-9000, 3PM Deadline'),
('01', 'OUTCLFCOR', 9001, 10000, 1, 1000, '16:00:00', 'POD Correspondent - Bin 9001-10000, 4PM Deadline');

-- COLLECTION_CODE_UD_REF — UserField/FedWorkType mapping (blank UserField, FedWorkType C)
INSERT IGNORE INTO COLLECTION_CODE_UD_REF (Coll_Type, OriginRT, UserField, FedWorkType, Coll_Code, Description) VALUES
('01', '061000140', '', 'C', 'OUTCLFBR',  'POD Branch - Forward (FedWorkType C)'),
('01', '061000141', '', 'C', 'OUTCLFATM', 'POD ATM - Forward (FedWorkType C)'),
('01', '061000142', '', 'C', 'OUTCLFMOB', 'POD Mobile - Forward (FedWorkType C)'),
('01', '061000143', '', 'C', 'OUTCLFRDC', 'POD RDC - Forward (FedWorkType C)'),
('01', '061000144', '', 'C', 'OUTCLFLBX', 'POD Lockbox - Forward (FedWorkType C)'),
('01', '061000145', '', 'C', 'OUTCLFCOR', 'POD Correspondent - Forward (FedWorkType C)');


-- ============================================================================
-- EIE Engine — Outgoing Returns
-- Coll_Type = 03 (Outgoing Return), unique Origin RT per posting source
-- ============================================================================

-- COLLECTION_CODE_ORIGRT_REF — maps Origin RT → Collection Code
INSERT IGNORE INTO COLLECTION_CODE_ORIGRT_REF (Coll_Type, OriginRT, Collection_Code, Description) VALUES
('03', '071000140', 'OUTCLRDDA', 'Outgoing Return - Core Banking DDA (NSF, Stop Pay, Acct Closed)'),
('03', '071000141', 'OUTCLRCD',  'Outgoing Return - Card System (Card Exceptions)'),
('03', '071000142', 'OUTCLRLN',  'Outgoing Return - Loan System (Loan Exceptions)');

-- COLLECTION_CODE_MICR — BIN range assignments for outgoing returns
INSERT IGNORE INTO COLLECTION_CODE_MICR (Coll_Type, Coll_Code, `Bin#Start`, `Bin#End`, BatchStart, BatchEnd, FileDeadline, Description) VALUES
('03', 'OUTCLRDDA', 10001, 11000, 1, 1000, NULL, 'Outgoing Return DDA - Bin 10001-11000, No Deadline'),
('03', 'OUTCLRCD',  11001, 12000, 1, 1000, NULL, 'Outgoing Return Card - Bin 11001-12000, No Deadline'),
('03', 'OUTCLRLN',  12001, 13000, 1, 1000, NULL, 'Outgoing Return Loan - Bin 12001-13000, No Deadline');

-- COLLECTION_CODE_UD_REF — UserField/FedWorkType mapping (blank UserField, FedWorkType C)
INSERT IGNORE INTO COLLECTION_CODE_UD_REF (Coll_Type, OriginRT, UserField, FedWorkType, Coll_Code, Description) VALUES
('03', '071000140', '', 'C', 'OUTCLRDDA', 'Outgoing Return DDA - (FedWorkType C)'),
('03', '071000141', '', 'C', 'OUTCLRCD',  'Outgoing Return Card - (FedWorkType C)'),
('03', '071000142', '', 'C', 'OUTCLRLN',  'Outgoing Return Loan - (FedWorkType C)');
