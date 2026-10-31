-- ============================================================================
-- SPEC_09 Phase 3: one-time release of non-payable credits left RESERVED by the CL engine (idempotent).
-- Apply AFTER the new CL engine is deployed.
-- ============================================================================
USE ${DB_NAME_PRIMARY};
UPDATE ITEM_DETAILS_ENRICHED ide
  JOIN ITEM_DETAILS id ON id.PAYMENT_ID = ide.PAYMENT_ID
   SET ide.CL_ITEM_STATUS = NULL, ide.CL_BUILD_STATUS = NULL
 WHERE ide.CL_ITEM_STATUS = 'RESERVED'
   AND ide.CL_FILE_SESSION_ID IS NULL
   AND (COALESCE(id.SYNTHESIZED_CREDIT,0) = 1 OR id.CREDIT_ITEM_TYPE IS NOT NULL)
   -- never touch a row reserved by a build request that is still running:
   -- (CL_BUILD_REQUEST is utf8mb4_0900_ai_ci, ITEM_DETAILS_ENRICHED is utf8mb4_unicode_ci: explicit COLLATE avoids ERROR 1267)
                   -- reserveItem stores the BUILD_REQUEST_ID in CL_BUILD_STATUS (AccumulationDataService.java:463-470)
   AND NOT EXISTS (SELECT 1 FROM CL_BUILD_REQUEST br
                    WHERE br.BUILD_REQUEST_ID COLLATE utf8mb4_unicode_ci = ide.CL_BUILD_STATUS
                      AND br.STATUS NOT IN ('COMPLETED','PARTIAL_SUCCESS','FAILED','CANCELLED'));
