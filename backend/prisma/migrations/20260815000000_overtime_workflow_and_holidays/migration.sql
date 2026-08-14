-- =============================================================================
-- ARTIFACT ONLY — DO NOT APPLY TO SUPABASE WITHOUT EXPLICIT USER APPROVAL.
-- =============================================================================
-- Migration artifact for Overtime multi-step workflow, OvertimeSession tracking,
-- and CompanyHoliday management.
--
-- STATUS: Artifact only. NOT applied to Supabase, Render, or any live database.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Enum Evolutions & New Enums
-- -----------------------------------------------------------------------------

-- Evolve OvertimeStatus enum to include multi-step workflow states while preserving existing values
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'pending_team_lead';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'pending_hr';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'rejected_by_team_lead';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'rejected_by_hr';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'cancelled';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'expired';
ALTER TYPE "OvertimeStatus" ADD VALUE IF NOT EXISTS 'completed';

-- Create OvertimeSessionStatus enum for dedicated session tracking
CREATE TYPE "OvertimeSessionStatus" AS ENUM ('active', 'completed', 'cancelled');

-- -----------------------------------------------------------------------------
-- 2. Evolve OvertimeRequest Table
-- -----------------------------------------------------------------------------
-- Add requested duration/timestamps, AttendanceRecord link, and Team Lead/HR decision audit fields
ALTER TABLE "OvertimeRequest" 
  ADD COLUMN "attendanceRecordId" TEXT,
  ADD COLUMN "requestedStartAt" TIMESTAMP(3),
  ADD COLUMN "requestedEndAt" TIMESTAMP(3),
  ADD COLUMN "requestedMinutes" INTEGER,
  ADD COLUMN "teamLeadId" TEXT,
  ADD COLUMN "teamLeadDecisionAt" TIMESTAMP(3),
  ADD COLUMN "teamLeadComment" TEXT,
  ADD COLUMN "hrApproverId" TEXT,
  ADD COLUMN "hrDecisionAt" TIMESTAMP(3),
  ADD COLUMN "hrComment" TEXT;

-- Foreign key for AttendanceRecord relation
ALTER TABLE "OvertimeRequest" 
  ADD CONSTRAINT "OvertimeRequest_attendanceRecordId_fkey" 
  FOREIGN KEY ("attendanceRecordId") REFERENCES "AttendanceRecord"("id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Foreign key for Team Lead audit relation
ALTER TABLE "OvertimeRequest" 
  ADD CONSTRAINT "OvertimeRequest_teamLeadId_fkey" 
  FOREIGN KEY ("teamLeadId") REFERENCES "User"("id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Foreign key for HR approver audit relation
ALTER TABLE "OvertimeRequest" 
  ADD CONSTRAINT "OvertimeRequest_hrApproverId_fkey" 
  FOREIGN KEY ("hrApproverId") REFERENCES "User"("id") 
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Performance indexes on OvertimeRequest
CREATE INDEX "OvertimeRequest_userId_date_idx" ON "OvertimeRequest"("userId", "date");
CREATE INDEX "OvertimeRequest_status_date_idx" ON "OvertimeRequest"("status", "date");
CREATE INDEX "OvertimeRequest_teamLeadId_status_date_idx" ON "OvertimeRequest"("teamLeadId", "status", "date");

-- -----------------------------------------------------------------------------
-- 3. Create OvertimeSession Table
-- -----------------------------------------------------------------------------
-- Dedicated session execution model for clocked overtime hours, with start & end geofence audit parameters
CREATE TABLE "OvertimeSession" (
    "id" TEXT NOT NULL,
    "overtimeRequestId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "attendanceRecordId" TEXT NOT NULL,
    "status" "OvertimeSessionStatus" NOT NULL DEFAULT 'active',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "actualMinutes" INTEGER,
    "startLocationLabel" TEXT,
    "startLatitude" DOUBLE PRECISION,
    "startLongitude" DOUBLE PRECISION,
    "startGpsAccuracy" DOUBLE PRECISION,
    "startDistanceMeters" DOUBLE PRECISION,
    "endLocationLabel" TEXT,
    "endLatitude" DOUBLE PRECISION,
    "endLongitude" DOUBLE PRECISION,
    "endGpsAccuracy" DOUBLE PRECISION,
    "endDistanceMeters" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OvertimeSession_pkey" PRIMARY KEY ("id")
);

-- Unique constraint ensuring maximum one session per approved OvertimeRequest
CREATE UNIQUE INDEX "OvertimeSession_overtimeRequestId_key" ON "OvertimeSession"("overtimeRequestId");

-- Foreign key constraints for OvertimeSession
ALTER TABLE "OvertimeSession" 
  ADD CONSTRAINT "OvertimeSession_overtimeRequestId_fkey" 
  FOREIGN KEY ("overtimeRequestId") REFERENCES "OvertimeRequest"("id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "OvertimeSession" 
  ADD CONSTRAINT "OvertimeSession_userId_fkey" 
  FOREIGN KEY ("userId") REFERENCES "User"("id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "OvertimeSession" 
  ADD CONSTRAINT "OvertimeSession_attendanceRecordId_fkey" 
  FOREIGN KEY ("attendanceRecordId") REFERENCES "AttendanceRecord"("id") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Performance index on OvertimeSession
CREATE INDEX "OvertimeSession_userId_startedAt_idx" ON "OvertimeSession"("userId", "startedAt");

-- -----------------------------------------------------------------------------
-- 4. Create CompanyHoliday Table
-- -----------------------------------------------------------------------------
-- Official company holidays table with date unique constraint
CREATE TABLE "CompanyHoliday" (
    "id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "name" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CompanyHoliday_pkey" PRIMARY KEY ("id")
);

-- Unique constraint on CompanyHoliday(date)
CREATE UNIQUE INDEX "CompanyHoliday_date_key" ON "CompanyHoliday"("date");

-- Foreign key constraint for creating User
ALTER TABLE "CompanyHoliday" 
  ADD CONSTRAINT "CompanyHoliday_createdById_fkey" 
  FOREIGN KEY ("createdById") REFERENCES "User"("id") 
  ON DELETE SET NULL ON UPDATE CASCADE;
