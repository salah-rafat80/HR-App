"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LeaveService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const events_gateway_1 = require("../events/events/events.gateway");
let LeaveService = class LeaveService {
    prisma;
    events;
    constructor(prisma, events) {
        this.prisma = prisma;
        this.events = events;
    }
    async getBalances(userId) {
        return this.prisma.leaveBalance.findMany({
            where: { userId },
        });
    }
    async getMyRequests(userId) {
        return this.prisma.leaveRequest.findMany({
            where: { userId },
            include: { approvalSteps: true, user: true },
            orderBy: { createdAt: 'desc' },
        });
    }
    async applyLeave(userId, data) {
        const request = await this.prisma.leaveRequest.create({
            data: {
                userId,
                type: data.type,
                startDate: new Date(data.startDate),
                endDate: new Date(data.endDate),
                isHalfDay: data.isHalfDay,
                halfDayPeriod: data.halfDayPeriod,
                reason: data.reason,
                hasAttachment: data.hasAttachment,
                overallStatus: 'pending',
                approvalSteps: {
                    create: [
                        { stepName: 'submitted', status: 'approved', timestamp: new Date() },
                        { stepName: 'manager', status: 'pending', timestamp: new Date() },
                        { stepName: 'hr', status: 'pending', timestamp: new Date() },
                        { stepName: 'final_approval', status: 'pending', timestamp: new Date() },
                    ]
                }
            },
            include: { approvalSteps: true, user: true },
        });
        const balances = await this.prisma.leaveBalance.findMany({ where: { userId, type: data.type } });
        if (balances.length > 0) {
            const b = balances[0];
            const start = new Date(data.startDate);
            const end = new Date(data.endDate);
            const diffTime = Math.abs(end.getTime() - start.getTime());
            const days = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
            await this.prisma.leaveBalance.update({
                where: { id: b.id },
                data: { daysUsed: b.daysUsed + days },
            });
        }
        this.events.emitEntityUpdated('LeaveRequest', 'created', request);
        return request;
    }
    async cancelRequest(id) {
        await this.prisma.leaveApprovalStep.deleteMany({ where: { requestId: id } });
        const deleted = await this.prisma.leaveRequest.delete({ where: { id } });
        this.events.emitEntityUpdated('LeaveRequest', 'deleted', deleted);
        return deleted;
    }
    async getTeamCalendar() {
        const requests = await this.prisma.leaveRequest.findMany({
            where: { overallStatus: 'approved' },
            include: { user: true },
        });
        return requests.map(r => ({
            colleagueName: r.user.name,
            startDate: r.startDate,
            endDate: r.endDate,
        }));
    }
    async getPendingApprovals() {
        return this.prisma.leaveRequest.findMany({
            where: { overallStatus: 'pending' },
            include: { approvalSteps: true, user: true },
            orderBy: { createdAt: 'desc' },
        });
    }
    async approveRequest(id) {
        const req = await this.prisma.leaveRequest.findUnique({
            where: { id },
            include: { approvalSteps: true },
        });
        if (!req)
            throw new common_1.NotFoundException();
        const pendingStep = req.approvalSteps.find(s => s.status === 'pending');
        if (pendingStep) {
            await this.prisma.leaveApprovalStep.update({
                where: { id: pendingStep.id },
                data: { status: 'approved', timestamp: new Date() },
            });
            const isLast = req.approvalSteps.indexOf(pendingStep) === req.approvalSteps.length - 1;
            const newStatus = isLast ? 'approved' : 'pending';
            const updated = await this.prisma.leaveRequest.update({
                where: { id },
                data: { overallStatus: newStatus },
                include: { approvalSteps: true, user: true },
            });
            this.events.emitEntityUpdated('LeaveRequest', 'updated', updated);
            return updated;
        }
    }
    async rejectRequest(id) {
        const req = await this.prisma.leaveRequest.findUnique({
            where: { id },
            include: { approvalSteps: true },
        });
        if (!req)
            throw new common_1.NotFoundException();
        const pendingStep = req.approvalSteps.find(s => s.status === 'pending');
        if (pendingStep) {
            await this.prisma.leaveApprovalStep.update({
                where: { id: pendingStep.id },
                data: { status: 'rejected', timestamp: new Date() },
            });
            const updated = await this.prisma.leaveRequest.update({
                where: { id },
                data: { overallStatus: 'rejected' },
                include: { approvalSteps: true, user: true },
            });
            this.events.emitEntityUpdated('LeaveRequest', 'updated', updated);
            return updated;
        }
    }
};
exports.LeaveService = LeaveService;
exports.LeaveService = LeaveService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        events_gateway_1.EventsGateway])
], LeaveService);
//# sourceMappingURL=leave.service.js.map