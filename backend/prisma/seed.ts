import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const saltRounds = 10;
  const commonPassword = await bcrypt.hash('password123', saltRounds);

  console.log('Seeding database...');

  // 1. Create Users
  const hrAdmin = await prisma.user.upsert({
    where: { email: 'hr@demo.com' },
    update: {},
    create: {
      email: 'hr@demo.com',
      password: commonPassword,
      name: 'HR Admin',
      role: 'hrAdmin',
    },
  });

  const manager = await prisma.user.upsert({
    where: { email: 'manager@demo.com' },
    update: {},
    create: {
      email: 'manager@demo.com',
      password: commonPassword,
      name: 'Manager User',
      role: 'manager',
    },
  });

  const employee1 = await prisma.user.upsert({
    where: { email: 'employee@demo.com' },
    update: {},
    create: {
      id: 'emp_1',
      email: 'employee@demo.com',
      password: commonPassword,
      name: 'Ahmed Salem',
      role: 'employee',
    },
  });

  const employee2 = await prisma.user.upsert({
    where: { email: 'emp2@demo.com' },
    update: {},
    create: {
      id: 'emp_2',
      email: 'emp2@demo.com',
      password: commonPassword,
      name: 'Mona Zaki',
      role: 'employee',
    },
  });

  // 2. Create Leave Balances for employee1
  const balances = [
    { type: 'annual', daysUsed: 6, daysTotal: 24 },
    { type: 'sick', daysUsed: 4, daysTotal: 10 },
    { type: 'emergency', daysUsed: 1, daysTotal: 3 },
    { type: 'maternityPaternity', daysUsed: 0, daysTotal: 90 },
    { type: 'unpaid', daysUsed: 0, daysTotal: 30 },
    { type: 'study', daysUsed: 0, daysTotal: 14 },
    { type: 'hajj', daysUsed: 0, daysTotal: 21 },
    { type: 'bereavement', daysUsed: 0, daysTotal: 5 },
  ];

  for (const b of balances) {
    await prisma.leaveBalance.create({
      data: {
        userId: employee1.id,
        type: b.type as any,
        daysUsed: b.daysUsed,
        daysTotal: b.daysTotal,
      },
    });
  }

  // 3. Create Leave Requests
  const now = new Date();

  // req_1: Approved Annual Leave (past)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_1' },
    update: {},
    create: {
      id: 'req_1',
      userId: employee1.id,
      type: 'annual',
      startDate: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() - 55 * 24 * 60 * 60 * 1000),
      isHalfDay: false,
      reason: 'Family Vacation',
      hasAttachment: false,
      overallStatus: 'approved',
      approvalSteps: {
        create: [
          { stepName: 'submitted', status: 'approved', timestamp: new Date(now.getTime() - 62 * 24 * 60 * 60 * 1000) },
          { stepName: 'manager', status: 'approved', timestamp: new Date(now.getTime() - 61 * 24 * 60 * 60 * 1000) },
          { stepName: 'hr', status: 'approved', timestamp: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000) },
          { stepName: 'final_approval', status: 'approved', timestamp: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000) },
        ],
      },
    },
  });

  // req_2: Approved Sick Leave (past)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_2' },
    update: {},
    create: {
      id: 'req_2',
      userId: employee1.id,
      type: 'sick',
      startDate: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() - 28 * 24 * 60 * 60 * 1000),
      isHalfDay: false,
      reason: 'Flu',
      hasAttachment: true,
      overallStatus: 'approved',
      approvalSteps: {
        create: [
          { stepName: 'submitted', status: 'approved', timestamp: new Date(now.getTime() - 32 * 24 * 60 * 60 * 1000) },
          { stepName: 'manager', status: 'approved', timestamp: new Date(now.getTime() - 31 * 24 * 60 * 60 * 1000) },
          { stepName: 'hr', status: 'approved', timestamp: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) },
          { stepName: 'final_approval', status: 'approved', timestamp: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) },
        ],
      },
    },
  });

  // req_3: Pending Emergency Leave (future)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_3' },
    update: {},
    create: {
      id: 'req_3',
      userId: employee1.id,
      type: 'emergency',
      startDate: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 12 * 24 * 60 * 60 * 1000),
      isHalfDay: false,
      reason: 'Personal Emergency',
      hasAttachment: false,
      overallStatus: 'pending',
      approvalSteps: {
        create: [
          { stepName: 'submitted', status: 'approved', timestamp: new Date() },
          { stepName: 'manager', status: 'pending', timestamp: new Date() },
          { stepName: 'hr', status: 'pending', timestamp: now },
          { stepName: 'final_approval', status: 'pending', timestamp: now },
        ],
      },
    },
  });

  // req_5: Mona Zaki's request (pending for manager to see)
  await prisma.leaveRequest.create({
    data: {
      id: 'req_5',
      userId: employee2.id,
      type: 'sick',
      startDate: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      isHalfDay: false,
      reason: 'Doctor Appointment',
      hasAttachment: true,
      overallStatus: 'pending',
      approvalSteps: {
        create: [
          { stepName: 'submitted', status: 'approved', timestamp: now },
          { stepName: 'manager', status: 'pending', timestamp: now },
          { stepName: 'hr', status: 'pending', timestamp: now },
          { stepName: 'final_approval', status: 'pending', timestamp: now },
        ],
      },
    },
  });

  console.log('Seeding completed.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
