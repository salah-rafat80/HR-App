-- Associate each employee with a persistent office branch.
-- The column is nullable during rollout; attendance and overtime services reject
-- operations for users with no assigned active branch.
ALTER TABLE "User" ADD COLUMN "branchId" TEXT;

CREATE INDEX "User_branchId_idx" ON "User"("branchId");

ALTER TABLE "User"
  ADD CONSTRAINT "User_branchId_fkey"
  FOREIGN KEY ("branchId") REFERENCES "OfficeBranch"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
