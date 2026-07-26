/*
  Warnings:

  - Added the required column `date` to the `AttendanceRecord` table without a default value. This is not possible if the table is not empty.
  - Added the required column `locationLabel` to the `AttendanceRecord` table without a default value. This is not possible if the table is not empty.
  - Added the required column `status` to the `AttendanceRecord` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `AttendanceRecord` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `AttendanceRecord` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('present', 'absent', 'late', 'workFromHome', 'onBusinessTrip', 'onLeave', 'none');

-- CreateEnum
CREATE TYPE "OvertimeStatus" AS ENUM ('pending', 'approved', 'rejected');

-- AlterTable
ALTER TABLE "AttendanceRecord" ADD COLUMN     "clockInTime" TIMESTAMP(3),
ADD COLUMN     "clockOutTime" TIMESTAMP(3),
ADD COLUMN     "date" DATE NOT NULL,
ADD COLUMN     "locationLabel" TEXT NOT NULL,
ADD COLUMN     "status" "AttendanceStatus" NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "userId" TEXT NOT NULL;

-- CreateTable
CREATE TABLE "ShiftInfo" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "shiftName" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ShiftInfo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OvertimeRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "hoursRequested" DOUBLE PRECISION NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "OvertimeStatus" NOT NULL DEFAULT 'pending',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OvertimeRequest_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "AttendanceRecord" ADD CONSTRAINT "AttendanceRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ShiftInfo" ADD CONSTRAINT "ShiftInfo_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OvertimeRequest" ADD CONSTRAINT "OvertimeRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
