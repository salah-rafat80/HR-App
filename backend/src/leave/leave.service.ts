import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';


@Injectable()
export class LeaveService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  async getBalances(userId: string) {
    return this.prisma.leaveBalance.findMany({
      where: { userId },
    });
  }

  async getMyRequests(userId: string) {
    return this.prisma.leaveRequest.findMany({
      where: { userId },
      include: { approvalSteps: true, user: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async applyLeave(userId: string, data: any) {
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

    // Deduct balance optimistically
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

  async cancelRequest(id: string) {
    await this.prisma.leaveApprovalStep.deleteMany({ where: { requestId: id } });
    const deleted = await this.prisma.leaveRequest.delete({ where: { id } });
    this.events.emitEntityUpdated('LeaveRequest', 'deleted', deleted);
    return deleted;
  }

  async getTeamCalendar() {
    // Simplified for demo: return all approved leaves
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
    // For demo, return all pending requests
    return this.prisma.leaveRequest.findMany({
      where: { overallStatus: 'pending' },
      include: { approvalSteps: true, user: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveRequest(id: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: { approvalSteps: true },
    });

    if (!req) throw new NotFoundException();

    const pendingStep = req.approvalSteps.find(s => s.status === 'pending');
    if (pendingStep) {
      await this.prisma.leaveApprovalStep.update({
        where: { id: pendingStep.id },
        data: { status: 'approved', timestamp: new Date() },
      });

      // Check if it was the last step
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

  async rejectRequest(id: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: { approvalSteps: true },
    });

    if (!req) throw new NotFoundException();

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
}
