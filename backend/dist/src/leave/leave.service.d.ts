import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
export declare class LeaveService {
    private prisma;
    private events;
    constructor(prisma: PrismaService, events: EventsGateway);
    getBalances(userId: string): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        daysUsed: number;
        daysTotal: number;
        userId: string;
    }[]>;
    getMyRequests(userId: string): Promise<({
        user: {
            id: string;
            email: string;
            password: string;
            name: string;
            role: string;
        };
        approvalSteps: {
            id: string;
            stepName: string;
            status: import("@prisma/client").$Enums.ApprovalStepStatus;
            timestamp: Date;
            requestId: string;
        }[];
    } & {
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    applyLeave(userId: string, data: any): Promise<{
        user: {
            id: string;
            email: string;
            password: string;
            name: string;
            role: string;
        };
        approvalSteps: {
            id: string;
            stepName: string;
            status: import("@prisma/client").$Enums.ApprovalStepStatus;
            timestamp: Date;
            requestId: string;
        }[];
    } & {
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    }>;
    cancelRequest(id: string): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    }>;
    getTeamCalendar(): Promise<{
        colleagueName: string;
        startDate: Date;
        endDate: Date;
    }[]>;
    getPendingApprovals(): Promise<({
        user: {
            id: string;
            email: string;
            password: string;
            name: string;
            role: string;
        };
        approvalSteps: {
            id: string;
            stepName: string;
            status: import("@prisma/client").$Enums.ApprovalStepStatus;
            timestamp: Date;
            requestId: string;
        }[];
    } & {
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    approveRequest(id: string): Promise<({
        user: {
            id: string;
            email: string;
            password: string;
            name: string;
            role: string;
        };
        approvalSteps: {
            id: string;
            stepName: string;
            status: import("@prisma/client").$Enums.ApprovalStepStatus;
            timestamp: Date;
            requestId: string;
        }[];
    } & {
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    }) | undefined>;
    rejectRequest(id: string): Promise<({
        user: {
            id: string;
            email: string;
            password: string;
            name: string;
            role: string;
        };
        approvalSteps: {
            id: string;
            stepName: string;
            status: import("@prisma/client").$Enums.ApprovalStepStatus;
            timestamp: Date;
            requestId: string;
        }[];
    } & {
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        userId: string;
        startDate: Date;
        endDate: Date;
        isHalfDay: boolean;
        halfDayPeriod: import("@prisma/client").$Enums.HalfDayPeriod | null;
        reason: string;
        hasAttachment: boolean;
        overallStatus: import("@prisma/client").$Enums.LeaveStatus;
        createdAt: Date;
        updatedAt: Date;
    }) | undefined>;
}
