import { LeaveService } from './leave.service';
import { CreateLeaveRequestDto } from './dto/create-leave-request.dto';
export declare class LeaveController {
    private readonly leaveService;
    constructor(leaveService: LeaveService);
    getBalances(req: any): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.LeaveType;
        daysUsed: number;
        daysTotal: number;
        userId: string;
    }[]>;
    getMyRequests(req: any): Promise<({
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
    applyLeave(req: any, data: CreateLeaveRequestDto): Promise<{
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
