-- Rollback Script for Migration: 20260813000000_production_schema_migration
-- WARNING: Only run on staging or after explicit database backup approval if migration fails.

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

-- 2. Drop AuditLog Table
DROP TABLE IF EXISTS "AuditLog" CASCADE;

-- 3. Revert Monetary Column Conversions (Decimal(12,2) -> DOUBLE PRECISION)
ALTER TABLE "PayrollRun" 
  ALTER COLUMN "totalAmount" TYPE DOUBLE PRECISION USING "totalAmount"::double precision,
  ALTER COLUMN "totalAmount" SET DEFAULT 0;

ALTER TABLE "Payslip" 
  ALTER COLUMN "baseSalary" TYPE DOUBLE PRECISION USING "baseSalary"::double precision,
  ALTER COLUMN "netPay" TYPE DOUBLE PRECISION USING "netPay"::double precision;

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
