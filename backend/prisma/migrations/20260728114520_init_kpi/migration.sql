/*
  Warnings:

  - Added the required column `currentValue` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `departmentObjective` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `description` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `targetValue` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `title` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Kpi` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `Kpi` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "AttendanceRecord" ADD COLUMN     "clockInLat" DOUBLE PRECISION,
ADD COLUMN     "clockInLng" DOUBLE PRECISION,
ADD COLUMN     "distanceMeters" DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "Kpi" ADD COLUMN     "currentValue" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "departmentObjective" TEXT NOT NULL,
ADD COLUMN     "description" TEXT NOT NULL,
ADD COLUMN     "hasEvidence" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "selfAssessmentText" TEXT,
ADD COLUMN     "targetValue" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "title" TEXT NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "userId" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "department" TEXT,
ADD COLUMN     "title" TEXT;

-- CreateTable
CREATE TABLE "CompanySettings" (
    "id" TEXT NOT NULL,
    "companyName" TEXT NOT NULL DEFAULT 'Demo Company',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CompanySettings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OfficeBranch" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "radiusMeters" INTEGER NOT NULL DEFAULT 200,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OfficeBranch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KpiQuarterScore" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "quarterLabel" TEXT NOT NULL,
    "averageScorePercent" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KpiQuarterScore_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Kpi" ADD CONSTRAINT "Kpi_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KpiQuarterScore" ADD CONSTRAINT "KpiQuarterScore_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
