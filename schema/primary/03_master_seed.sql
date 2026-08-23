-- ============================================================================
-- check_payment_platform MASTER/REFERENCE tables only (no transactional data)
-- Used by seed_tenant.py for clean tenant seeding
-- Run against: check_payment_platform database
-- ============================================================================

USE ${DB_NAME_PRIMARY};

-- Seed: ACCOUNT_PRODUCT_LIMIT (14 rows)
INSERT IGNORE INTO ACCOUNT_PRODUCT_LIMIT (PRODUCT_CODE, PRODUCT_NAME, PRODUCT_FAMILY, MAX_CHECK_AMOUNT, CURRENCY_CODE, MAX_DAILY_TOTAL, MAX_MONTHLY_TOTAL, REQUIRES_POSPAY, POSPAY_THRESHOLD, EFFECTIVE_DATE, EXPIRY_DATE, ACTIVE_FLAG) VALUES
('BASIC_CHECKING', 'Basic / Low-Balance Checking', 'CONSUMER', 25000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('COMMERCIAL_DDA', 'Commercial DDA', 'COMMERCIAL', 5000000.00, 'USD', NULL, NULL, 1, 500000.00, '2026-01-01', NULL, 1),
('CONSUMER_CHECKING', 'Consumer Checking', 'CONSUMER', 100000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('CONSUMER_SAVINGS', 'Consumer Savings', 'CONSUMER', 50000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('CORP_TREASURY', 'Corporate Treasury Account', 'COMMERCIAL', 10000000.00, 'USD', NULL, NULL, 1, 1000000.00, '2026-01-01', NULL, 1),
('ESCROW', 'Escrow Account', 'SPECIAL', 1000000.00, 'USD', NULL, NULL, 1, 250000.00, '2026-01-01', NULL, 1),
('GOVT', 'Government Account', 'SPECIAL', 999999999.99, 'USD', NULL, NULL, 1, 1000000.00, '2026-01-01', NULL, 1),
('NON_PROFIT', 'Non-Profit Account', 'SPECIAL', 250000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('PRO_SERVICES_LLC', 'Professional Services (LLC)', 'SMB', 1000000.00, 'USD', NULL, NULL, 1, 250000.00, '2026-01-01', NULL, 1),
('SMB_CHECKING', 'Small Business Checking', 'SMB', 500000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('SOLE_PROP_DDA', 'Sole Proprietor DDA', 'SMB', 250000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('STUDENT_YOUTH', 'Student / Youth Account', 'CONSUMER', 10000.00, 'USD', NULL, NULL, 0, NULL, '2026-01-01', NULL, 1),
('TRUST_IOLTA', 'Trust / IOLTA', 'SPECIAL', 250000.00, 'USD', NULL, NULL, 1, 100000.00, '2026-01-01', NULL, 1),
('ZBA', 'Zero Balance Account (ZBA)', 'COMMERCIAL', 10000000.00, 'USD', NULL, NULL, 1, 1000000.00, '2026-01-01', NULL, 1);

-- Seed: PRIORITY_BAND_MASTER (5 rows)
INSERT IGNORE INTO PRIORITY_BAND_MASTER (priority_band, severity_order, severity_name, description, auto_return_flag, ops_repairable_flag, active_flag) VALUES
('P0', 0, 'FRAUD_CRITICAL', 'Fraud or counterfeit risk. Immediate escalation to fraud queue. Highest severity.', 1, 0, 1),
('P1', 1, 'TECHNICAL_HARD_REJECT', 'Image or format invalid. Cannot process item technically. Auto return.', 1, 0, 1),
('P2', 2, 'BUSINESS_POSTING_RETURN', 'Valid image but posting/business rule failure. Return or posting review required.', 1, 0, 1),
('P3', 3, 'REPAIRABLE_QUALITY', 'Readable but requires manual operator repair or correction.', 0, 1, 1),
('P4', 4, 'COSMETIC_MINOR', 'Minor quality issues. Informational or low impact.', 0, 1, 1);

-- Seed: REVIEW_OUTCOME_MASTER (4 rows)
INSERT IGNORE INTO REVIEW_OUTCOME_MASTER (review_outcome_code, review_outcome_name, mapped_x9_code, active_flag) VALUES
('AMOUNT_UNREADABLE', 'Amount cannot be determined', 'W', 1),
('IMAGE_UNUSABLE', 'Image unusable / missing required info', 'U', 1),
('MICR_UNREADABLE', 'MICR / RT / Account cannot be determined', 'B', 1),
('READABLE_OK', 'Readable / No blocking issue', NULL, 1);

-- Seed: EXCEPTION_MASTER (27 rows)
INSERT IGNORE INTO EXCEPTION_MASTER (exception_code, exception_name, exception_category, priority_band, rank_in_band, ops_repairable_flag, default_queue, default_x9_code, active_flag) VALUES
('ACCOUNT_CLOSED', 'Account Closed', 'POSTING', 'P2', 3, 0, 'RETURN', 'R', 1),
('ACCOUNT_FROZEN', 'Account Frozen', 'POSTING', 'P2', 4, 0, 'RETURN', 'S', 1),
('ACCOUNT_NOT_FOUND', 'Account Not Found', 'POSTING', 'P2', 5, 0, 'RETURN', 'B', 1),
('AMOUNT_UNREADABLE', 'Amount Unreadable', 'IMAGE', 'P3', 1, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'W', 1),
('COUNTERFEIT_SUSPECTED', 'Counterfeit Suspected', 'FRAUD', 'P0', 1, 0, 'FRAUD_REVIEW', 'N', 1),
('DATE_UNREADABLE', 'Date Unreadable', 'IMAGE', 'P3', 4, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'I', 1),
('ENDORSEMENT_MISSING', 'Endorsement Missing', 'IMAGE', 'P2', 9, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'J', 1),
('EXCEED_ITEM_LIMIT', 'Exceeds Item Limit', 'POSTING', 'P2', 10, 0, 'RETURN', 'P', 1),
('EXCESSIVE_BLUR', 'Excessive Blur', 'IMAGE', 'P4', 3, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('EXCESSIVE_NOISE', 'Excessive Noise', 'IMAGE', 'P4', 6, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('IMAGE_CORRUPTED', 'Image Corrupted', 'IMAGE', 'P1', 1, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1),
('IMAGE_MISSING', 'Image Missing', 'IMAGE', 'P1', 3, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1),
('IMAGE_SKEW_CROP', 'Image Skew or Crop', 'IMAGE', 'P4', 1, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('INVALID_FORMAT', 'Invalid Image Format', 'IMAGE', 'P1', 2, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1),
('INVALID_RT', 'Invalid Routing Number', 'POSTING', 'P2', 6, 0, 'RETURN', 'B', 1),
('LOW_CONTRAST', 'Low Contrast', 'IMAGE', 'P4', 2, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('MICR_UNREADABLE', 'MICR Unreadable', 'IMAGE', 'P3', 2, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'B', 1),
('NOT_OUR_ITEM', 'Not Our Item', 'POSTING', 'P2', 7, 0, 'RETURN', 'B', 1),
('OVERSIZED_IMAGE', 'Oversized Image', 'IMAGE', 'P1', 4, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1),
('PAYEE_UNREADABLE', 'Payee Unreadable', 'IMAGE', 'P3', 5, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1),
('POOR_RESOLUTION', 'Poor Resolution', 'IMAGE', 'P4', 4, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('POSITIVE_PAY_RETURN', 'Positive Pay Return', 'POSTING', 'P2', 2, 0, 'RETURN', NULL, 1),
('ROUTING_NUMBER_INVALID', 'Routing Number Invalid', 'IMAGE', 'P3', 3, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'B', 1),
('SIGNATURE_MISSING', 'Drawer Signature Missing', 'IMAGE', 'P2', 8, 0, 'FROM_CDE_TO_IMAGE_REVIEW', 'L', 1),
('STOP_PAY_RETURN', 'Stop Payment Return', 'POSTING', 'P2', 1, 0, 'RETURN', 'C', 1),
('STREAK_DETECTED', 'Streak Detected', 'IMAGE', 'P4', 5, 1, 'FROM_CDE_TO_IMAGE_REVIEW', NULL, 1),
('UNDERSIZED_IMAGE', 'Undersized Image', 'IMAGE', 'P4', 7, 1, 'FROM_CDE_TO_IMAGE_REVIEW', 'U', 1);

-- Seed: EXCEPTION_WORKFLOW_RULE (23 rows)
INSERT IGNORE INTO EXCEPTION_WORKFLOW_RULE (exception_code, queue_name, ops_can_key_amount, ops_can_key_date, ops_can_key_payee, ops_can_key_micr_rt, ops_can_key_micr_acct, ops_can_key_micr_serial, if_success_next_state, if_fail_action, if_fail_x9_code, active_flag) VALUES
('ACCOUNT_CLOSED', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'R', 1),
('ACCOUNT_FROZEN', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'S', 1),
('ACCOUNT_NOT_FOUND', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'B', 1),
('AMOUNT_UNREADABLE', 'AMOUNT_REVIEW', 1, 0, 0, 0, 0, 0, 'REEVALUATE', 'RETURN', 'W', 1),
('COUNTERFEIT_SUSPECTED', 'FRAUD_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'N', 1),
('DATE_UNREADABLE', 'DATE_REVIEW', 0, 1, 0, 0, 0, 0, 'REEVALUATE', 'RETURN', 'I', 1),
('ENDORSEMENT_MISSING', 'ENDORSEMENT_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'J', 1),
('EXCEED_ITEM_LIMIT', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'P', 1),
('EXCESSIVE_BLUR', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('EXCESSIVE_NOISE', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('IMAGE_SKEW_CROP', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('INVALID_RT', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'B', 1),
('LOW_CONTRAST', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('MICR_UNREADABLE', 'MICR_REVIEW', 0, 0, 0, 1, 1, 1, 'REEVALUATE', 'RETURN', 'B', 1),
('NOT_OUR_ITEM', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'B', 1),
('PAYEE_UNREADABLE', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('POOR_RESOLUTION', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('POSITIVE_PAY_RETURN', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', NULL, 1),
('ROUTING_NUMBER_INVALID', 'MICR_REVIEW', 0, 0, 0, 1, 1, 1, 'REEVALUATE', 'RETURN', 'B', 1),
('SIGNATURE_MISSING', 'SIGNATURE_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'L', 1),
('STOP_PAY_RETURN', 'POSTING_REVIEW', 0, 0, 0, 0, 0, 0, 'CONTINUE', 'RETURN', 'C', 1),
('STREAK_DETECTED', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1),
('UNDERSIZED_IMAGE', 'IMAGE_REVIEW', 0, 0, 1, 0, 0, 0, 'REEVALUATE', 'RETURN', NULL, 1);

-- Seed: EXCEPTION_X9_CONDITION_MAP (20 rows)
INSERT IGNORE INTO EXCEPTION_X9_CONDITION_MAP (exception_code, condition_type, condition_value, x9_return_code, active_flag) VALUES
('EXCESSIVE_BLUR', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('EXCESSIVE_BLUR', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('EXCESSIVE_BLUR', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('EXCESSIVE_NOISE', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('EXCESSIVE_NOISE', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('EXCESSIVE_NOISE', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('IMAGE_SKEW_CROP', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('IMAGE_SKEW_CROP', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('IMAGE_SKEW_CROP', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('LOW_CONTRAST', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('LOW_CONTRAST', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('LOW_CONTRAST', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('POOR_RESOLUTION', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('POOR_RESOLUTION', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('POOR_RESOLUTION', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('POSITIVE_PAY_RETURN', 'POSPAY_STOP_VOID', 'Y', 'C', 1),
('STREAK_DETECTED', 'REVIEW_OUTCOME', 'AMOUNT_UNREADABLE', 'W', 1),
('STREAK_DETECTED', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1),
('STREAK_DETECTED', 'REVIEW_OUTCOME', 'MICR_UNREADABLE', 'B', 1),
('UNDERSIZED_IMAGE', 'REVIEW_OUTCOME', 'IMAGE_UNUSABLE', 'U', 1);

-- Seed: CL_FILE_PROFILE (2 rows)
INSERT IGNORE INTO CL_FILE_PROFILE (FILE_PROFILE_ID, PROFILE_NAME, FORMAT_TYPE, DEST_RT, ORIG_RT, DEST_NAME, ORIG_NAME, STANDARD_LEVEL, TEST_INDICATOR, COUNTRY_CODE, MAX_BUNDLE_ITEMS, ACTIVE) VALUES
(1, 'X9_FORWARD_STD', 'X9_FORWARD_STD', '999999999', '111111111', 'DEST BANK', 'ORIG BANK', '35', 'T', 'US', 300, 1),
(2, 'X9_RETURN_ICLR', 'X9_RETURN_ICLR', '111111111', '999999999', 'ORIG BANK', 'DEST BANK', '35', 'T', 'US', 300, 1);

-- Seed: ADE_APPROVAL_RULES (6 rows)
INSERT IGNORE INTO ADE_APPROVAL_RULES (RULE_ID, COLLECTION_CODE, CORRECTION_TYPE, THRESHOLD_AMOUNT, REQUIRES_APPROVAL, ALLOWED_ROLES, ACTIVE) VALUES
(1, 'INCLFF', 'ENCODED_AMOUNT_CORRECTION', 500.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1),
(2, 'INCLFF', 'DATA_CORRECTION', 0.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1),
(3, 'INCLRF', 'ENCODED_AMOUNT_CORRECTION', 500.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1),
(4, 'INCLRF', 'DATA_CORRECTION', 0.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1),
(5, 'ONUS', 'ENCODED_AMOUNT_CORRECTION', 500.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1),
(6, 'ONUS', 'DATA_CORRECTION', 0.00, 0, 'REPAIR_OPERATOR,SUPERVISOR', 1);
