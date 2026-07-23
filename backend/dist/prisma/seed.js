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
    const now = new Date();
    await prisma.leaveRequest.create({
        data: {
            id: 'req_1',
            userId: employee1.id,
            type: 'annual',
            startDate: new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000),
            endDate: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
            isHalfDay: false,
            reason: 'Family Vacation',
            hasAttachment: false,
            overallStatus: 'approved',
            approvalSteps: {
                create: [
                    { stepName: 'submitted', status: 'approved', timestamp: new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000) },
                    { stepName: 'manager', status: 'approved', timestamp: new Date(now.getTime() - 9 * 24 * 60 * 60 * 1000) },
                    { stepName: 'hr', status: 'approved', timestamp: new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000) },
                    { stepName: 'final_approval', status: 'approved', timestamp: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) },
                ],
            },
        },
    });
    await prisma.leaveRequest.create({
        data: {
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
    await prisma.leaveRequest.create({
        data: {
            id: 'req_3',
            userId: employee1.id,
            type: 'emergency',
            startDate: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
            endDate: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
            isHalfDay: true,
            halfDayPeriod: 'morning',
            reason: 'Personal Errands',
            hasAttachment: false,
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
//# sourceMappingURL=seed.js.map