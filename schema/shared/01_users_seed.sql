-- ============================================================================
-- USERS seed — Default operator/admin users for ACCS UI login
-- Run against: check_payment_platform database
--
-- Credentials:
--   admin01 / admin123   (ADMIN)
--   sup01   / Super@123  (AUDITOR)
--   ops01   / Oper@123   (OPERATOR)
-- ============================================================================

USE ${DB_NAME_PRIMARY};

INSERT INTO users (name, email, password, role, status, created_at, updated_at) VALUES
  ('admin01', 'admin@accs.com', '$2a$10$2JpfjeKPjcolR8ZBEV0ar.Iet/BpAXTO17jIEw/u0snu9KcZECPW.', 'ADMIN', 'ACTIVE', NOW(), NOW()),
  ('sup01', 'supervisor@accs.com', '$2a$10$offfd0KrYoM21SHXuXBbVOqKHy2Mwk12BTligVjEBxA6fnWAmWhxu', 'AUDITOR', 'ACTIVE', NOW(), NOW()),
  ('ops01', 'operator@accs.com', '$2a$10$DbVshal1Tb06QjwEhzodY.sbDMLbGVE18R4heBHJmsc9xLNEyMT9u', 'OPERATOR', 'ACTIVE', NOW(), NOW())
ON DUPLICATE KEY UPDATE status = 'ACTIVE', updated_at = NOW();
