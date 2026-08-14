-- Rollback Script for Migration: 20260813000000_production_schema_migration
-- WARNING: Executing schema rollback on production or populated staging environments requires review.
-- 
-- IMPORTANT DATA SAFETY AUDIT RULE:
-- 1. DROP TABLE "AuditLog" is STRICTLY PROHIBITED after audit log records have been written.
-- 2. If AuditLog contains persistent security audit events, DO NOT drop the table. Use point-in-time restore instead.
-- 3. DROP TABLE is ONLY permitted on clean staging environments prior to audit data generation.

BEGIN;

-- 1. Drop Indexes & Unique Constraints
DROP INDEX IF EXISTS "Payslip_userId_payrollRunId_key";
DROP INDEX IF EXISTS "Payslip_userId_idx";
DROP INDEX IF EXISTS "Kpi_userId_idx";
DROP INDEX IF EXISTS "LeaveRequest_userId_idx";
DROP INDEX IF EXISTS "AttendanceRecord_userId_idx";
DROP INDEX IF EXISTS "BonusNotice_userId_idx";
DROP INDEX IF EXISTS "User_employeeCode_idx";
DROP INDEX IF EXISTS "User_employeeCode_key";

-- 2. AuditLog Pre-write Safety Check (Do not drop if table has records)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'AuditLog') THEN
    IF (SELECT COUNT(*) FROM "AuditLog") > 0 THEN
      RAISE EXCEPTION 'ROLLBACK SAFETY ABORT: AuditLog table contains active audit logs. Drop table prohibited.';
    ELSE
      DROP TABLE "AuditLog" CASCADE;
    END IF;
  END IF;
END $$;

-- 3. Revert Monetary Column Conversions (Decimal(12,2) -> DOUBLE PRECISION)
ALTER TABLE "PayrollRun" 
  ALTER COLUMN "totalAmount" TYPE DOUBLE PRECISION USING "totalAmount"::double precision,
  ALTER COLUMN "totalAmount" SET DEFAULT 0;

ALTER TABLE "Payslip" 
  ALTER COLUMN "baseSalary" TYPE DOUBLE PRECISION USING "baseSalary"::double precision,
  ALTER COLUMN "netPay" TYPE DOUBLE PRECISION USING "netPay"::double precision,
  ALTER COLUMN "payrollRunId" DROP NOT NULL;

ALTER TABLE "PayslipLineItem" 
  ALTER COLUMN "amount" TYPE DOUBLE PRECISION USING "amount"::double precision;

ALTER TABLE "BonusNotice" 
  ALTER COLUMN "amount" TYPE DOUBLE PRECISION USING "amount"::double precision;

-- 4. Remove User lifecycle & identity fields
ALTER TABLE "User" 
  DROP COLUMN IF EXISTS "employeeCode",
  DROP COLUMN IF EXISTS "isActive",
  DROP COLUMN IF EXISTS "passwordChangedAt",
  DROP COLUMN IF EXISTS "createdAt",
  DROP COLUMN IF EXISTS "updatedAt";

COMMIT;
