-- ============================================================================
-- COLLECTION_TYPE_MASTER — Maps X9 CollectionTypeIndicator → Collection Type
-- For MCB RT 026013356
-- Run against: business_rules database
-- ============================================================================

USE ${DB_NAME_BUSINESS_RULES};

INSERT IGNORE INTO COLLECTION_TYPE_MASTER (X9_Coll_Type_Ind, File_Dest_RT, Collection_Type, Description)
VALUES
  (1, '026013356', '01', 'Forward Presentment Inclearing - MCB RT'),
  (2, '026013356', '02', 'Return Presentment Inclearing - MCB RT')
ON DUPLICATE KEY UPDATE Description = VALUES(Description);
