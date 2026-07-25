-- AlterTable
ALTER TABLE "LeaveApprovalStep" ALTER COLUMN "stepOrder" SET DEFAULT 0;

-- AlterTable
ALTER TABLE "LeaveRequest" ADD COLUMN     "currentStepOrder" INTEGER NOT NULL DEFAULT 1;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "managerId" TEXT;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
