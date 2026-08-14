-- Migration Artifact: KPI Performance Optimization Indexes
-- Supporting exact queries used in KpiService and team performance lookups.
-- IMPORTANT: This is a repository artifact for staging review. DO NOT run against production/Supabase without explicit approval.

-- 1. Index supporting User manager hierarchy lookups in KpiService.getManagedUserIds
-- Query: SELECT id FROM "User" WHERE "managerId" IN (...) AND "role" = 'employee'
CREATE INDEX IF NOT EXISTS "User_managerId_role_idx" ON "User"("managerId", "role");

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
-- Query: SELECT "userId" FROM "AttendanceRecord" WHERE "userId" IN (...) AND "date" BETWEEN $1 AND $2 AND "status" = 'workFromHome'
CREATE INDEX IF NOT EXISTS "AttendanceRecord_userId_date_status_idx" ON "AttendanceRecord"("userId", "date", "status");
