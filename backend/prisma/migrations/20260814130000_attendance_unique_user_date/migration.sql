-- =============================================================================
-- ARTIFACT ONLY — NOT APPLIED TO ANY DATABASE
-- =============================================================================
-- This migration artifact proposes adding a unique constraint on
-- AttendanceRecord(userId, date) to prevent concurrent duplicate check-ins
-- for the same user on the same calendar day.
--
-- STATUS: Not applied to Supabase, Render, or any database.
-- APPLY ONLY after explicit approval and a preflight check that no duplicate
-- (userId, date) rows exist in the live database.
--
-- Preflight check before applying:
--   SELECT "userId", "date", COUNT(*)
--   FROM "AttendanceRecord"
--   GROUP BY "userId", "date"
--   HAVING COUNT(*) > 1;
-- If the above returns rows, backfill or de-duplicate before applying.
-- =============================================================================

ALTER TABLE "AttendanceRecord"
ADD CONSTRAINT "AttendanceRecord_userId_date_key"
UNIQUE ("userId", "date");
