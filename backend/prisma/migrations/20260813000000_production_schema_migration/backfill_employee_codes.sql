-- HR-Approved Employee Code Backfill Template
-- Instructions for HR Admin:
-- 1. Replace the sample database UUIDs and employee codes with verified HR roster codes.
-- 2. Execute on staging PostgreSQL database before enforcing NOT NULL constraints.

BEGIN;

-- Verified HR Roster Backfill Statements (Sample Mapping)
-- UPDATE "User" SET "employeeCode" = 'EMP-0001' WHERE id = 'user-uuid-1';
-- UPDATE "User" SET "employeeCode" = 'EMP-0002' WHERE id = 'user-uuid-2';
-- UPDATE "User" SET "employeeCode" = 'HR-0001'  WHERE id = 'user-uuid-3';

-- Validation Query: Assert 0 remaining NULL employeeCode records before enforcing constraint
SELECT id, email, name, role, "employeeCode" 
FROM "User" 
WHERE "employeeCode" IS NULL;

-- Once zero rows are returned by the validation query above, enforce NOT NULL:
-- ALTER TABLE "User" ALTER COLUMN "employeeCode" SET NOT NULL;

COMMIT;
