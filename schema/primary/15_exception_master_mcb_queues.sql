-- ============================================================================
-- EXCEPTION_MASTER — tenant-prefixed default_queue values (MCB_)
-- Replaces leftover unprefixed FROM_* SQS names. Category names RETURN and
-- FRAUD_REVIEW are left unchanged (not physical queue names).
-- Run against: check_payment_platform (${DB_NAME_PRIMARY})
-- ============================================================================

USE ${DB_NAME_PRIMARY};

UPDATE EXCEPTION_MASTER
SET default_queue = 'MCB_FROM_CDE_TO_IMAGE_REVIEW'
WHERE default_queue IN (
  'FROM_CDE_TO_IMAGE_REVIEW',
  'FROM_CDE_TO_IMAGE_REPAIR'
);

UPDATE EXCEPTION_MASTER
SET default_queue = 'MCB_FROM_CDE_TO_PAYMENT_REPAIR'
WHERE default_queue = 'FROM_CDE_TO_PAYMENT_REPAIR';

UPDATE EXCEPTION_MASTER
SET default_queue = 'MCB_FROM_CDE_TO_FRAUD_REVIEW'
WHERE default_queue = 'FROM_CDE_TO_FRAUD_REVIEW';

UPDATE EXCEPTION_MASTER
SET default_queue = 'MCB_FROM_CDE_TO_SUPERVISOR_APPROVAL'
WHERE default_queue = 'FROM_CDE_TO_SUPERVISOR_APPROVAL';

SELECT default_queue, COUNT(*) AS rows
FROM EXCEPTION_MASTER
GROUP BY default_queue
ORDER BY default_queue;
