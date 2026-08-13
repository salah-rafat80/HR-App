-- Migration: 20260813000000_production_schema_migration
-- Description: Staging-ready non-destructive migration introducing AuditLog, Decimal conversion, nullable employeeCode, and Payslip idempotency constraint.

-- 1. Add User lifecycle & identity fields
ALTER TABLE "User" 
  ADD COLUMN IF NOT EXISTS "employeeCode" TEXT,
  ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "passwordChangedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS "User_employeeCode_key" ON "User"("employeeCode") WHERE "employeeCode" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "User_employeeCode_idx" ON "User"("employeeCode");

-- 2. Create AuditLog Table
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

ALTER TABLE "AuditLog" 
  ADD CONSTRAINT "AuditLog_actorUserId_fkey" 
  FOREIGN KEY ("actorUserId") REFERENCES "User"("id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS "AuditLog_timestamp_idx" ON "AuditLog"("timestamp");
CREATE INDEX IF NOT EXISTS "AuditLog_actorUserId_idx" ON "AuditLog"("actorUserId");
CREATE INDEX IF NOT EXISTS "AuditLog_targetType_targetId_idx" ON "AuditLog"("targetType", "targetId");

-- 3. Monetary Schema Conversions (Float -> Decimal(12,2))
ALTER TABLE "PayrollRun" 
  ALTER COLUMN "totalAmount" TYPE DECIMAL(12,2) USING "totalAmount"::numeric(12,2),
  ALTER COLUMN "totalAmount" SET DEFAULT 0;

ALTER TABLE "Payslip" 
  ALTER COLUMN "baseSalary" TYPE DECIMAL(12,2) USING "baseSalary"::numeric(12,2),
  ALTER COLUMN "netPay" TYPE DECIMAL(12,2) USING "netPay"::numeric(12,2);

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
