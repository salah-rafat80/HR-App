-- Migration SQL artifact for KPI performance indexes
-- NOTE: This artifact is created for staging database review. DO NOT apply directly in production without approval.

-- 1. Index supporting User manager hierarchy lookups in KpiService.getManagedUserIds
-- Query: SELECT id FROM "User" WHERE "managerId" IN (...)
CREATE INDEX IF NOT EXISTS "User_managerId_idx" ON "User"("managerId");

-- 2. Index supporting KpiQuarterScore user queries ordered by quarterLabel desc in KpiService.getHistoricalScores
-- Query: SELECT * FROM "KpiQuarterScore" WHERE "userId" = $1 ORDER BY "quarterLabel" DESC
CREATE INDEX IF NOT EXISTS "KpiQuarterScore_userId_quarterLabel_idx" ON "KpiQuarterScore"("userId", "quarterLabel" DESC);

-- 3. Composite Index supporting Kpi user queries ordered by createdAt desc in KpiService.getCurrentKpis
-- Query: SELECT * FROM "Kpi" WHERE "userId" = $1 ORDER BY "createdAt" DESC
CREATE INDEX IF NOT EXISTS "Kpi_userId_createdAt_idx" ON "Kpi"("userId", "createdAt" DESC);

-- 4. Index supporting LeaveRequest status checks for team members in KpiService.getTeamKpis
-- Query: SELECT "userId" FROM "LeaveRequest" WHERE "userId" IN (...) AND "overallStatus" = 'approved' AND "startDate" <= $1 AND "endDate" >= $2
CREATE INDEX IF NOT EXISTS "LeaveRequest_userId_overallStatus_startDate_endDate_idx" ON "LeaveRequest"("userId", "overallStatus", "startDate", "endDate");

-- 5. Index supporting AttendanceRecord WFH checks for team members in KpiService.getTeamKpis
-- Query: SELECT "userId" FROM "AttendanceRecord" WHERE "userId" IN (...) AND "status" = 'workFromHome' AND "date" BETWEEN $1 AND $2
CREATE INDEX IF NOT EXISTS "AttendanceRecord_userId_status_date_idx" ON "AttendanceRecord"("userId", "status", "date");
