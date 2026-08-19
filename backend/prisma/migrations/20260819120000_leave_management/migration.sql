-- CreateTable
CREATE TABLE "LeavePolicy" (
    "id" TEXT NOT NULL,
    "type" "LeaveType" NOT NULL,
    "displayNameAr" TEXT NOT NULL,
    "annualEntitlement" DECIMAL(12,2) NOT NULL,
    "isPaid" BOOLEAN NOT NULL DEFAULT true,
    "requiresBalance" BOOLEAN NOT NULL DEFAULT true,
    "allowHalfDay" BOOLEAN NOT NULL DEFAULT true,
    "minimumNoticeDays" INTEGER NOT NULL DEFAULT 0,
    "requiresReason" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "LeavePolicy_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LeaveBalanceAdjustment" (
    "id" TEXT NOT NULL,
    "balanceId" TEXT NOT NULL,
    "adjustmentDays" DECIMAL(12,2) NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LeaveBalanceAdjustment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CompanyLeaveApprovalConfiguration" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "finalHrApproverId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "CompanyLeaveApprovalConfiguration_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LeavePolicy_type_key" ON "LeavePolicy"("type");

-- AlterTable
ALTER TABLE "LeaveBalance"
ADD COLUMN "year" INTEGER,
ADD COLUMN "entitledDays" DECIMAL(12,2),
ADD COLUMN "adjustmentDays" DECIMAL(12,2) DEFAULT 0,
ADD COLUMN "reservedDays" DECIMAL(12,2) DEFAULT 0,
ADD COLUMN "usedDays" DECIMAL(12,2) DEFAULT 0;

-- CreateIndex
CREATE UNIQUE INDEX "LeaveBalance_userId_type_year_key" ON "LeaveBalance"("userId", "type", "year");

-- AlterTable
ALTER TABLE "LeaveRequest"
ADD COLUMN "workingDays" DECIMAL(12,2);

-- AlterTable
ALTER TABLE "LeaveApprovalStep"
ADD COLUMN "expectedApproverId" TEXT;

-- AddForeignKey
ALTER TABLE "LeaveBalanceAdjustment" ADD CONSTRAINT "LeaveBalanceAdjustment_balanceId_fkey" FOREIGN KEY ("balanceId") REFERENCES "LeaveBalance"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompanyLeaveApprovalConfiguration" ADD CONSTRAINT "CompanyLeaveApprovalConfiguration_finalHrApproverId_fkey" FOREIGN KEY ("finalHrApproverId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeaveApprovalStep" ADD CONSTRAINT "LeaveApprovalStep_expectedApproverId_fkey" FOREIGN KEY ("expectedApproverId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "LeaveApprovalStep_expectedApproverId_idx" ON "LeaveApprovalStep"("expectedApproverId");
