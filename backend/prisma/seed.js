"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcrypt = __importStar(require("bcrypt"));
const pg_1 = require("pg");
const adapter_pg_1 = require("@prisma/adapter-pg");
const pool = new pg_1.Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
async function main() {
    const saltRounds = 10;
    const commonPassword = await bcrypt.hash('password123', saltRounds);
    console.log('Seeding database...');
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
                type: b.type,
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
    console.log('Seeding completed.');
}
main()
    .catch((e) => {
    console.error(e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
});
