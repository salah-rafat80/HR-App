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

  // Seed the 13 required test users
  const requiredUsers = [
    { employeeCode: 'TEST-EMP-001', name: 'جنى حسن', role: 'employee', department: 'IT', title: 'QA Engineer', passwordRaw: 'HrTest!2026-A9' },
    { employeeCode: 'TEST-MGR-001', name: 'محمود فوزي', role: 'manager', department: 'الحسابات', title: 'Accounting Manager', passwordRaw: 'HrTest!2026-B7' },
    { employeeCode: 'TEST-TL-001', name: 'عمر نبيل', role: 'team_lead', department: 'IT', title: 'Engineering Team Lead', passwordRaw: 'HrTest!2026-C3' },
    { employeeCode: 'TEST-HR-001', name: 'سلمى عادل', role: 'hr', department: 'HR', title: 'HR Operations Specialist', passwordRaw: 'HrTest!2026-D5' },
    { employeeCode: 'TEST-HRA-001', name: 'داليا مصطفى', role: 'hrAdmin', department: 'HR', title: 'HR Administration Lead', passwordRaw: 'HrTest!2026-E8' },
    { employeeCode: 'TEST-SA-001', name: 'طارق أمين', role: 'superAdmin', department: 'IT', title: 'System Administrator', passwordRaw: 'HrTest!2026-F4' },
    { employeeCode: 'TEST-EMP-002', name: 'حسام محمود', role: 'employee', department: 'IT', title: 'Flutter Developer', passwordRaw: 'HrTest!2026-G1' },
    { employeeCode: 'TEST-EMP-003', name: 'نور شريف', role: 'employee', department: 'IT', title: 'Backend Developer', passwordRaw: 'HrTest!2026-H2' },
    { employeeCode: 'TEST-TL-002', name: 'أميرة وائل', role: 'team_lead', department: 'الحسابات', title: 'Finance Team Lead', passwordRaw: 'HrTest!2026-I3' },
    { employeeCode: 'TEST-EMP-004', name: 'يوسف عادل', role: 'employee', department: 'الحسابات', title: 'Senior Accountant', passwordRaw: 'HrTest!2026-J4' },
    { employeeCode: 'TEST-EMP-005', name: 'مريم هاني', role: 'employee', department: 'الحسابات', title: 'Accounts Payable Accountant', passwordRaw: 'HrTest!2026-K5' },
    { employeeCode: 'TEST-EMP-006', name: 'ريم أحمد', role: 'employee', department: 'HR', title: 'HR Coordinator', passwordRaw: 'HrTest!2026-L6' },
    { employeeCode: 'TEST-EMP-007', name: 'خالد سعد', role: 'employee', department: 'HR', title: 'Talent Acquisition Specialist', passwordRaw: 'HrTest!2026-M7' },
  ];

  for (const u of requiredUsers) {
    const hashedPassword = await bcrypt.hash(u.passwordRaw, saltRounds);
    const email = `${u.employeeCode.toLowerCase()}@demo.com`;
    await prisma.user.upsert({
      where: { email },
      update: {
        employeeCode: u.employeeCode,
        name: u.name,
        role: u.role,
        department: u.department,
        title: u.title,
        password: hashedPassword,
      },
      create: {
        email,
        employeeCode: u.employeeCode,
        name: u.name,
        role: u.role,
        department: u.department,
        title: u.title,
        password: hashedPassword,
      },
    });
  }

  // 1. Create Users
  const hrAdmin = await prisma.user.upsert({
    where: { email: 'hr@demo.com' },
    update: { department: 'HR', title: 'HR Manager' },
    create: {
      email: 'hr@demo.com',
      password: commonPassword,
      name: 'HR Admin',
      role: 'hr',
      department: 'HR',
      title: 'HR Manager',
    },
  });

  const manager = await prisma.user.upsert({
    where: { email: 'manager@demo.com' },
    update: { managerId: null, department: 'Engineering', title: 'Engineering Director' },
    create: {
      email: 'manager@demo.com',
      password: commonPassword,
      name: 'Manager User',
      role: 'manager',
      managerId: null,
      department: 'Engineering',
      title: 'Engineering Director',
    },
  });

  const teamLead = await prisma.user.upsert({
    where: { email: 'teamlead@demo.com' },
    update: { managerId: manager.id, department: 'Engineering', title: 'Team Lead' },
    create: {
      email: 'teamlead@demo.com',
      password: commonPassword,
      name: 'Team Lead',
      role: 'team_lead',
      managerId: manager.id,
      department: 'Engineering',
      title: 'Team Lead',
    },
  });

  const employee1 = await prisma.user.upsert({
    where: { email: 'employee@demo.com' },
    update: { managerId: teamLead.id, department: 'Engineering', title: 'Frontend Developer' },
    create: {
      id: 'emp_1',
      email: 'employee@demo.com',
      password: commonPassword,
      name: 'Ahmed Salem',
      role: 'employee',
      managerId: teamLead.id,
      department: 'Engineering',
      title: 'Frontend Developer',
    },
  });

  const employee2 = await prisma.user.upsert({
    where: { email: 'emp2@demo.com' },
    update: { managerId: teamLead.id, department: 'Engineering', title: 'Backend Developer' },
    create: {
      id: 'emp_2',
      email: 'emp2@demo.com',
      password: commonPassword,
      name: 'Mona Zaki',
      role: 'employee',
      managerId: teamLead.id,
      department: 'Engineering',
      title: 'Backend Developer',
    },
  });

  const employee3 = await prisma.user.upsert({
    where: { email: 'emp3@demo.com' },
    update: { managerId: teamLead.id, department: 'Engineering', title: 'QA Engineer' },
    create: {
      id: 'emp_3',
      email: 'emp3@demo.com',
      password: commonPassword,
      name: 'Omar Farooq',
      role: 'employee',
      managerId: teamLead.id,
      department: 'Engineering',
      title: 'QA Engineer',
    },
  });

  const employee4 = await prisma.user.upsert({
    where: { email: 'emp4@demo.com' },
    update: { managerId: manager.id, department: 'Product', title: 'Product Manager' },
    create: {
      id: 'emp_4',
      email: 'emp4@demo.com',
      password: commonPassword,
      name: 'Sara Ali',
      role: 'employee',
      managerId: manager.id,
      department: 'Product',
      title: 'Product Manager',
    },
  });

  const employee5 = await prisma.user.upsert({
    where: { email: 'emp5@demo.com' },
    update: { managerId: manager.id, department: 'Product', title: 'UI/UX Designer' },
    create: {
      id: 'emp_5',
      email: 'emp5@demo.com',
      password: commonPassword,
      name: 'Tariq Hassan',
      role: 'employee',
      managerId: manager.id,
      department: 'Product',
      title: 'UI/UX Designer',
    },
  });

  const employee6 = await prisma.user.upsert({
    where: { email: 'emp6@demo.com' },
    update: { managerId: hrAdmin.id, department: 'HR', title: 'HR Generalist' },
    create: {
      id: 'emp_6',
      email: 'emp6@demo.com',
      password: commonPassword,
      name: 'Nour Youssef',
      role: 'employee',
      managerId: hrAdmin.id,
      department: 'HR',
      title: 'HR Generalist',
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
    update: { currentStepOrder: 4 },
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
      currentStepOrder: 4,
      approvalSteps: {
        create: [
          { stepName: 'team_lead', status: 'approved', stepOrder: 1, timestamp: new Date(now.getTime() - 62 * 24 * 60 * 60 * 1000) },
          { stepName: 'manager', status: 'approved', stepOrder: 2, timestamp: new Date(now.getTime() - 61 * 24 * 60 * 60 * 1000) },
          { stepName: 'hr', status: 'approved', stepOrder: 3, timestamp: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000) },
        ],
      },
    },
  });

  // req_2: Approved Sick Leave (past)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_2' },
    update: { currentStepOrder: 4 },
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
      currentStepOrder: 4,
      approvalSteps: {
        create: [
          { stepName: 'team_lead', status: 'approved', stepOrder: 1, timestamp: new Date(now.getTime() - 32 * 24 * 60 * 60 * 1000) },
          { stepName: 'manager', status: 'approved', stepOrder: 2, timestamp: new Date(now.getTime() - 31 * 24 * 60 * 60 * 1000) },
          { stepName: 'hr', status: 'approved', stepOrder: 3, timestamp: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) },
        ],
      },
    },
  });

  // req_3: Pending Emergency Leave (future)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_3' },
    update: { currentStepOrder: 2 },
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
      currentStepOrder: 2,
      approvalSteps: {
        create: [
          { stepName: 'team_lead', status: 'approved', stepOrder: 1, timestamp: new Date() },
          { stepName: 'manager', status: 'pending', stepOrder: 2, timestamp: new Date() },
          { stepName: 'hr', status: 'pending', stepOrder: 3, timestamp: now },
        ],
      },
    },
  });

  // req_5: Mona Zaki's request (pending for manager to see)
  await prisma.leaveRequest.upsert({
    where: { id: 'req_5' },
    update: { currentStepOrder: 1 },
    create: {
      id: 'req_5',
      userId: employee2.id,
      type: 'sick',
      startDate: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
      endDate: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      isHalfDay: false,
      reason: 'Doctor Appointment',
      hasAttachment: true,
      overallStatus: 'pending',
      currentStepOrder: 1,
      approvalSteps: {
        create: [
          { stepName: 'team_lead', status: 'pending', stepOrder: 1, timestamp: now },
          { stepName: 'manager', status: 'pending', stepOrder: 2, timestamp: now },
          { stepName: 'hr', status: 'pending', stepOrder: 3, timestamp: now },
        ],
      },
    },
  });

  // 4. Create Company Settings
  await prisma.companySettings.upsert({
    where: { id: 'default_settings' },
    update: {},
    create: {
      id: 'default_settings',
      companyName: 'Demo Company',
    },
  });

  await prisma.officeBranch.upsert({
    where: { id: 'branch_main' },
    update: {
      latitude: 30.286884,
      longitude: 31.756905,
      radiusMeters: 200,
    },
    create: {
      id: 'branch_main',
      name: 'Main Office',
      latitude: 30.286884,
      longitude: 31.756905,
      radiusMeters: 200,
      isActive: true,
    },
  });

  // 5. Seed KPIs
  console.log('Seeding KPIs...');
  
  // emp_1 (Ahmed Salem) - Average: 85%
  const emp1Kpis = [
    { title: 'Customer Satisfaction Score', description: 'Maintain average CSAT.', departmentObjective: 'Improve customer support', targetValue: 5.0, currentValue: 4.5 },
    { title: 'Bug Resolution Time', description: 'Average bug fix time.', departmentObjective: 'Reduce defects', targetValue: 10.0, currentValue: 8.0 },
    { title: 'Feature Delivery', description: 'Epics completed.', departmentObjective: 'Accelerate product roadmap', targetValue: 100.0, currentValue: 90.0 },
    { title: 'Code Coverage', description: 'Unit test code coverage.', departmentObjective: 'Improve software quality', targetValue: 80.0, currentValue: 64.0 },
  ];
  for (const kpi of emp1Kpis) {
    await prisma.kpi.create({ data: { userId: 'emp_1', ...kpi } });
  }

  // emp_2 (Mona Zaki) - Average: 92%
  await prisma.kpi.create({
    data: { userId: 'emp_2', title: 'API Performance Optimization', description: 'Optimize backend response times.', departmentObjective: 'Improve backend speed', targetValue: 10.0, currentValue: 9.2 }
  });

  // emp_3 (Omar Farooq) - Average: 78%
  await prisma.kpi.create({
    data: { userId: 'emp_3', title: 'Automation Test Coverage', description: 'Write end-to-end integration tests.', departmentObjective: 'Increase automated quality checks', targetValue: 10.0, currentValue: 7.8 }
  });

  // emp_4 (Sara Ali) - Average: 88%
  await prisma.kpi.create({
    data: { userId: 'emp_4', title: 'Product Backlog Health', description: 'Keep backlog items detailed and prioritized.', departmentObjective: 'Define product requirements clearly', targetValue: 10.0, currentValue: 8.8 }
  });

  // emp_5 (Tariq Hassan) - Average: 95%
  await prisma.kpi.create({
    data: { userId: 'emp_5', title: 'User Research Session Count', description: 'Perform customer feedback interviews.', departmentObjective: 'Align designs with user needs', targetValue: 10.0, currentValue: 9.5 }
  });

  // emp_6 (Nour Youssef) - Average: 80%
  await prisma.kpi.create({
    data: { userId: 'emp_6', title: 'Employee Onboarding Time', description: 'Streamline onboarding for new hires.', departmentObjective: 'Improve HR efficiency', targetValue: 10.0, currentValue: 8.0 }
  });

  // Historical Quarter Scores for employee1
  const historicalScores = [
    { quarterLabel: 'Q2 2025', averageScorePercent: 0.72 },
    { quarterLabel: 'Q3 2025', averageScorePercent: 0.78 },
    { quarterLabel: 'Q4 2025', averageScorePercent: 0.81 },
    { quarterLabel: 'Q1 2026', averageScorePercent: 0.85 },
  ];
  for (const score of historicalScores) {
    await prisma.kpiQuarterScore.create({ data: { userId: 'emp_1', ...score } });
  }

  // 6. Seed Appraisal Data
  console.log('Seeding Appraisal data...');
  
  const appraisalCycle = await prisma.appraisalCycle.upsert({
    where: { id: 'cycle_q2_2026' },
    update: {
      label: 'Q2 2026 Review',
      status: 'inProgress',
      dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days from now
    },
    create: {
      id: 'cycle_q2_2026',
      label: 'Q2 2026 Review',
      status: 'inProgress',
      dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days from now
    },
  });

  // Seed peer feedback requests for emp_1 if none exist
  const peerFeedbackCount = await prisma.peerFeedback.count({
    where: { cycleId: appraisalCycle.id },
  });
  if (peerFeedbackCount === 0) {
    await prisma.peerFeedback.createMany({
      data: [
        {
          fromUserId: 'emp_1',
          toUserId: 'emp_5', // Tariq Hassan
          cycleId: appraisalCycle.id,
          feedbackText: 'Great teamwork and design skills.',
          submitted: true,
        },
        {
          fromUserId: 'emp_1',
          toUserId: 'emp_2', // Mona Zaki
          cycleId: appraisalCycle.id,
          feedbackText: null,
          submitted: false,
        },
        {
          fromUserId: 'emp_1',
          toUserId: 'emp_3', // Omar Farooq
          cycleId: appraisalCycle.id,
          feedbackText: null,
          submitted: false,
        },
      ],
    });
  }

  // Seed category ratings for emp_1 results screen if none exist
  const categoryRatingCount = await prisma.appraisalCategoryRating.count({
    where: { userId: 'emp_1', cycleId: appraisalCycle.id },
  });
  if (categoryRatingCount === 0) {
    await prisma.appraisalCategoryRating.createMany({
      data: [
        {
          userId: 'emp_1',
          cycleId: appraisalCycle.id,
          categoryName: 'Communication',
          score: 4.5,
          managerComment: 'Clear and proactive.',
        },
        {
          userId: 'emp_1',
          cycleId: appraisalCycle.id,
          categoryName: 'Technical Skill',
          score: 4.0,
          managerComment: 'Solid performance.',
        },
        {
          userId: 'emp_1',
          cycleId: appraisalCycle.id,
          categoryName: 'Teamwork',
          score: 4.8,
          managerComment: 'Excellent collaboration.',
        },
        {
          userId: 'emp_1',
          cycleId: appraisalCycle.id,
          categoryName: 'Ownership',
          score: 3.5,
          managerComment: 'Good, but needs more initiative.',
        },
      ],
    });
  }

  // Seed development goals for emp_1 if none exist
  const developmentGoalCount = await prisma.developmentGoal.count({
    where: { userId: 'emp_1' },
  });
  if (developmentGoalCount === 0) {
    await prisma.developmentGoal.createMany({
      data: [
        {
          userId: 'emp_1',
          title: 'Master Flutter Animations',
          progressPercent: 0.6,
        },
        {
          userId: 'emp_1',
          title: 'Lead a technical deep-dive',
          progressPercent: 0.2,
        },
        {
          userId: 'emp_1',
          title: 'Improve test coverage in core module',
          progressPercent: 0.9,
        },
      ],
    });
  }

  // Seed career steps for emp_1 if none exist
  const careerStepCount = await prisma.careerStep.count({
    where: { userId: 'emp_1' },
  });
  if (careerStepCount === 0) {
    await prisma.careerStep.createMany({
      data: [
        {
          userId: 'emp_1',
          roleTitle: 'Junior Developer',
          status: 'completed',
          order: 1,
        },
        {
          userId: 'emp_1',
          roleTitle: 'Mid-Level Developer',
          status: 'completed',
          order: 2,
        },
        {
          userId: 'emp_1',
          roleTitle: 'Senior Developer',
          status: 'current',
          order: 3,
        },
        {
          userId: 'emp_1',
          roleTitle: 'Tech Lead',
          status: 'upcoming',
          order: 4,
        },
        {
          userId: 'emp_1',
          roleTitle: 'Engineering Manager',
          status: 'upcoming',
          order: 5,
        },
      ],
    });
  }

  console.log('Seeding completed.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect(); await pool.end();
  });
