-- Migration: 20260815120000_server_authoritative_egypt_time
-- Description: Convert instant columns to timestamptz(3) and leave_request start/end dates to date.
-- STATUS: UNAPPLIED (Awaiting explicit owner approval. DO NOT EXECUTE DIRECTLY).

-- AUDIT FINDINGS:
-- Existing NestJS Prisma driver writes new Date().toISOString() into PostgreSQL timestamp columns.
-- Historic values were saved as UTC wall-clock values without timezone metadata.
-- Conversion strategy uses `AT TIME ZONE 'UTC'` to convert naïve UTC wall-clock values into explicit TIMESTAMPTZ(3) without shifting.

-- 1. User
ALTER TABLE "User" ALTER COLUMN "passwordChangedAt" TYPE TIMESTAMPTZ(3) USING "passwordChangedAt" AT TIME ZONE 'UTC';
ALTER TABLE "User" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "User" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 2. AuditLog
ALTER TABLE "AuditLog" ALTER COLUMN "timestamp" TYPE TIMESTAMPTZ(3) USING "timestamp" AT TIME ZONE 'UTC';

-- 3. LeaveRequest
ALTER TABLE "LeaveRequest" ALTER COLUMN "startDate" TYPE DATE USING "startDate"::date;
ALTER TABLE "LeaveRequest" ALTER COLUMN "endDate" TYPE DATE USING "endDate"::date;
ALTER TABLE "LeaveRequest" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "LeaveRequest" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 4. LeaveApprovalStep
ALTER TABLE "LeaveApprovalStep" ALTER COLUMN "timestamp" TYPE TIMESTAMPTZ(3) USING "timestamp" AT TIME ZONE 'UTC';

-- 5. AttendanceRecord
ALTER TABLE "AttendanceRecord" ALTER COLUMN "clockInTime" TYPE TIMESTAMPTZ(3) USING "clockInTime" AT TIME ZONE 'UTC';
ALTER TABLE "AttendanceRecord" ALTER COLUMN "clockOutTime" TYPE TIMESTAMPTZ(3) USING "clockOutTime" AT TIME ZONE 'UTC';
ALTER TABLE "AttendanceRecord" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "AttendanceRecord" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 6. CompanySettings
ALTER TABLE "CompanySettings" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "CompanySettings" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 7. OfficeBranch
ALTER TABLE "OfficeBranch" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "OfficeBranch" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 8. ShiftInfo
ALTER TABLE "ShiftInfo" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "ShiftInfo" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 9. OvertimeRequest
ALTER TABLE "OvertimeRequest" ALTER COLUMN "requestedStartAt" TYPE TIMESTAMPTZ(3) USING "requestedStartAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeRequest" ALTER COLUMN "requestedEndAt" TYPE TIMESTAMPTZ(3) USING "requestedEndAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeRequest" ALTER COLUMN "teamLeadDecisionAt" TYPE TIMESTAMPTZ(3) USING "teamLeadDecisionAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeRequest" ALTER COLUMN "hrDecisionAt" TYPE TIMESTAMPTZ(3) USING "hrDecisionAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeRequest" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeRequest" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 10. OvertimeSession
ALTER TABLE "OvertimeSession" ALTER COLUMN "startedAt" TYPE TIMESTAMPTZ(3) USING "startedAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeSession" ALTER COLUMN "endedAt" TYPE TIMESTAMPTZ(3) USING "endedAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeSession" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "OvertimeSession" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 11. CompanyHoliday
ALTER TABLE "CompanyHoliday" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "CompanyHoliday" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 12. Kpi & KpiQuarterScore
ALTER TABLE "Kpi" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "Kpi" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "KpiQuarterScore" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "KpiQuarterScore" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 13. AppraisalCycle, SelfAppraisalAnswer, PeerFeedback, AppraisalCategoryRating, DevelopmentGoal, CareerStep
ALTER TABLE "AppraisalCycle" ALTER COLUMN "dueDate" TYPE TIMESTAMPTZ(3) USING "dueDate" AT TIME ZONE 'UTC';
ALTER TABLE "AppraisalCycle" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "AppraisalCycle" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "SelfAppraisalAnswer" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "SelfAppraisalAnswer" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "PeerFeedback" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "PeerFeedback" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "AppraisalCategoryRating" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "AppraisalCategoryRating" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "DevelopmentGoal" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "DevelopmentGoal" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "CareerStep" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "CareerStep" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 14. PayrollRun, Payslip, PayslipLineItem, BonusNotice
ALTER TABLE "PayrollRun" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "PayrollRun" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "Payslip" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "Payslip" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "PayslipLineItem" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "PayslipLineItem" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';
ALTER TABLE "BonusNotice" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "BonusNotice" ALTER COLUMN "updatedAt" TYPE TIMESTAMPTZ(3) USING "updatedAt" AT TIME ZONE 'UTC';

-- 15. Auxiliary models
ALTER TABLE "TrainingCourse" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "JobRequisition" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "Candidate" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "OrgNode" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "NewHireOnboarding" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
ALTER TABLE "OffboardingCase" ALTER COLUMN "createdAt" TYPE TIMESTAMPTZ(3) USING "createdAt" AT TIME ZONE 'UTC';
