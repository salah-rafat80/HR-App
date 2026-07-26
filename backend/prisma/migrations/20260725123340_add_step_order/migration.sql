/*
  Warnings:

  - Added the required column `stepOrder` to the `LeaveApprovalStep` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "LeaveApprovalStep" ADD COLUMN     "stepOrder" INTEGER NOT NULL;
