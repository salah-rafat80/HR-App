-- Migration: 20260813000000_production_schema_migration
-- Description: Transactional & Idempotency-safe production schema migration with Preflight Data Checks.

BEGIN;

-- =========================================================
-- PREFLIGHT INTEGRITY CHECKS (Execute before any DDL)
-- =========================================================

-- Preflight Check 1: Detect NaN or Infinity floating values in monetary columns
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "Payslip" WHERE "baseSalary" = 'NaN'::float OR "baseSalary" = 'Infinity'::float OR "netPay" = 'NaN'::float OR "netPay" = 'Infinity'::float
    UNION ALL
    SELECT 1 FROM "PayslipLineItem" WHERE "amount" = 'NaN'::float OR "amount" = 'Infinity'::float
    UNION ALL
    SELECT 1 FROM "PayrollRun" WHERE "totalAmount" = 'NaN'::float OR "totalAmount" = 'Infinity'::float
    UNION ALL
    SELECT 1 FROM "BonusNotice" WHERE "amount" = 'NaN'::float OR "amount" = 'Infinity'::float
  ) THEN
    RAISE EXCEPTION 'PREFLIGHT FAILURE: Invalid Float values (NaN or Infinity) detected in monetary columns';
  END IF;
END $$;

-- Preflight Check 2: Detect monetary values outside Decimal(12,2) range [-9,999,999,999.99, 9,999,999,999.99]
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "Payslip" WHERE ABS("baseSalary") > 9999999999.99 OR ABS("netPay") > 9999999999.99
    UNION ALL
    SELECT 1 FROM "PayslipLineItem" WHERE ABS("amount") > 9999999999.99
    UNION ALL
    SELECT 1 FROM "PayrollRun" WHERE ABS("totalAmount") > 9999999999.99
    UNION ALL
    SELECT 1 FROM "BonusNotice" WHERE ABS("amount") > 9999999999.99
  ) THEN
    RAISE EXCEPTION 'PREFLIGHT FAILURE: Monetary values exceeding Decimal(12,2) range detected';
  END IF;
END $$;

-- Preflight Check 3: Detect orphaned Payslips with NULL payrollRunId (Auto-backfill synthetic migration run)
DO $$
DECLARE
  migration_run_id TEXT := 'legacy-preflight-migration-run';
BEGIN
  IF EXISTS (SELECT 1 FROM "Payslip" WHERE "payrollRunId" IS NULL) THEN
    INSERT INTO "PayrollRun" ("id", "periodLabel", "status", "totalAmount", "employeeCount", "createdAt", "updatedAt")
    VALUES (migration_run_id, 'Legacy Backfill Run', 'approved', 0, 0, NOW(), NOW())
    ON CONFLICT ("id") DO NOTHING;

    UPDATE "Payslip"
    SET "payrollRunId" = migration_run_id
    WHERE "payrollRunId" IS NULL;
  END IF;
END $$;

-- Preflight Check 4: Assert 0 duplicate (userId, payrollRunId) pairs before creating unique index
DO $$
BEGIN
  IF EXISTS (
    SELECT "userId", "payrollRunId"
    FROM "Payslip"
    WHERE "payrollRunId" IS NOT NULL
    GROUP BY "userId", "payrollRunId"
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'PREFLIGHT FAILURE: Duplicate (userId, payrollRunId) pairs found in Payslip table';
  END IF;
END $$;


-- =========================================================
-- SCHEMA DDL ALTERATIONS
-- =========================================================

-- 1. Add User lifecycle & identity fields
ALTER TABLE "User" 
  ADD COLUMN IF NOT EXISTS "employeeCode" TEXT,
  ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "passwordChangedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS "User_employeeCode_key" ON "User"("employeeCode") WHERE "employeeCode" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "User_employeeCode_idx" ON "User"("employeeCode");

-- 2. Create AuditLog Table (Idempotent)
CREATE TABLE IF NOT EXISTS "AuditLog" (
    "id" TEXT NOT NULL,
    "actorUserId" TEXT,
    "action" TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "targetId" TEXT,
    "metadata" JSONB,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'AuditLog_actorUserId_fkey'
  ) THEN
    ALTER TABLE "AuditLog" 
      ADD CONSTRAINT "AuditLog_actorUserId_fkey" 
      FOREIGN KEY ("actorUserId") REFERENCES "User"("id") 
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "AuditLog_timestamp_idx" ON "AuditLog"("timestamp");
CREATE INDEX IF NOT EXISTS "AuditLog_actorUserId_idx" ON "AuditLog"("actorUserId");
CREATE INDEX IF NOT EXISTS "AuditLog_targetType_targetId_idx" ON "AuditLog"("targetType", "targetId");

-- 3. Monetary Schema Conversions (Float -> Decimal(12,2))
ALTER TABLE "PayrollRun" 
  ALTER COLUMN "totalAmount" TYPE DECIMAL(12,2) USING "totalAmount"::numeric(12,2),
  ALTER COLUMN "totalAmount" SET DEFAULT 0;

ALTER TABLE "Payslip" 
  ALTER COLUMN "baseSalary" TYPE DECIMAL(12,2) USING "baseSalary"::numeric(12,2),
  ALTER COLUMN "netPay" TYPE DECIMAL(12,2) USING "netPay"::numeric(12,2),
  ALTER COLUMN "payrollRunId" SET NOT NULL;

ALTER TABLE "PayslipLineItem" 
  ALTER COLUMN "amount" TYPE DECIMAL(12,2) USING "amount"::numeric(12,2);

ALTER TABLE "BonusNotice" 
  ALTER COLUMN "amount" TYPE DECIMAL(12,2) USING "amount"::numeric(12,2);

-- 4. Idempotency & Lookup Indexes
CREATE UNIQUE INDEX IF NOT EXISTS "Payslip_userId_payrollRunId_key" ON "Payslip"("userId", "payrollRunId");
CREATE INDEX IF NOT EXISTS "Payslip_userId_idx" ON "Payslip"("userId");
CREATE INDEX IF NOT EXISTS "Kpi_userId_idx" ON "Kpi"("userId");
CREATE INDEX IF NOT EXISTS "LeaveRequest_userId_idx" ON "LeaveRequest"("userId");
CREATE INDEX IF NOT EXISTS "AttendanceRecord_userId_idx" ON "AttendanceRecord"("userId");
CREATE INDEX IF NOT EXISTS "BonusNotice_userId_idx" ON "BonusNotice"("userId");

COMMIT;
