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
        update: {},
        create: {
            email: 'hr@demo.com',
            password: commonPassword,
            name: 'HR Admin',
            role: 'hr',
        },
    });
    const teamLead = await prisma.user.upsert({
        where: { email: 'teamlead@demo.com' },
        update: {},
        create: {
            email: 'teamlead@demo.com',
            password: commonPassword,
            name: 'Team Lead',
            role: 'team_lead',
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
        update: {},
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
            approvalSteps: {
                create: [
                    { stepName: 'team_lead', status: 'pending', stepOrder: 1, timestamp: now },
                    { stepName: 'manager', status: 'pending', stepOrder: 2, timestamp: now },
                    { stepName: 'hr', status: 'pending', stepOrder: 3, timestamp: now },
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
