-- Enforce one active overtime request per employee per calendar day.
-- The preflight prevents an index creation failure from being mistaken for a safe state.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM "OvertimeRequest"
    WHERE "status" IN ('pending_team_lead', 'pending_hr', 'approved')
    GROUP BY "userId", "date"
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Cannot create OvertimeRequest_one_active_per_user_date_key: duplicate active requests exist';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "OvertimeRequest_one_active_per_user_date_key"
ON "OvertimeRequest" ("userId", "date")
WHERE "status" IN ('pending_team_lead', 'pending_hr', 'approved');
