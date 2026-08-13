import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';

@Injectable()
export class LeaveService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
    private notifications: NotificationService,
  ) {}

  async getBalances(userId: string) {
    return this.prisma.leaveBalance.findMany({
      where: { userId },
    });
  }

  async getMyRequests(userId: string) {
    return this.prisma.leaveRequest.findMany({
      where: { userId },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: true,
      },
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
        currentStepOrder: 1,
        approvalSteps: {
          create: [
            {
              stepName: 'team_lead',
              status: 'pending',
              stepOrder: 1,
              timestamp: new Date(),
            },
            {
              stepName: 'manager',
              status: 'pending',
              stepOrder: 2,
              timestamp: new Date(),
            },
            {
              stepName: 'hr',
              status: 'pending',
              stepOrder: 3,
              timestamp: new Date(),
            },
          ],
        },
      },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: true,
      },
    });

    // Deduct balance optimistically if balance record exists
    const balances = await this.prisma.leaveBalance.findMany({
      where: { userId, type: data.type },
    });
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

    // Notify the employee
    this.events.emitToUser(userId, 'created', request);
    this.events.emitToRole('team_lead', 'created', request);
    this.events.emitToRole('manager', 'created', request);
    this.events.emitToRole('hr', 'created', request);
    this.events.emitToRole('hrAdmin', 'created', request);

    const managerId = request.user?.managerId;
    if (managerId) {
      this.events.emitToUser(managerId, 'created', request);

      const manager = await this.prisma.user.findUnique({
        where: { id: managerId },
      });

      if (manager?.fcmToken) {
        this.notifications.notifyNewLeaveRequest(
          manager.fcmToken,
          request.user?.name ?? 'Employee',
          request.id,
        );
      }
    }

    return request;
  }

  async cancelRequest(id: string) {
    await this.prisma.leaveApprovalStep.deleteMany({
      where: { requestId: id },
    });
    const deleted = await this.prisma.leaveRequest.delete({ where: { id } });
    this.events.emitEntityUpdated('LeaveRequest', 'deleted', deleted);
    return deleted;
  }

  async getTeamCalendar() {
    const requests = await this.prisma.leaveRequest.findMany({
      where: { overallStatus: 'approved' },
      include: { user: true },
    });

    return requests.map((r) => ({
      colleagueName: r.user.name,
      startDate: r.startDate,
      endDate: r.endDate,
    }));
  }

  async getPendingApprovals(role: string, actorUserId: string) {
    let stepOrder: number | null = null;

    if (role === 'hr' || role === 'hrAdmin') {
      stepOrder = 3;
    } else if (role === 'team_lead') {
      stepOrder = 1;
    } else if (role === 'manager') {
      stepOrder = 2;
    } else {
      return [];
    }

    return this.prisma.leaveRequest.findMany({
      where: { overallStatus: 'pending', currentStepOrder: stepOrder },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveRequest(id: string, actorUserId: string, actorRole: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: { include: { manager: true } },
      },
    });

    if (!req) throw new NotFoundException('Leave request not found');
    if (req.overallStatus !== 'pending') {
      throw new ForbiddenException('Request is not pending');
    }

    // Authorization checks
    if (req.currentStepOrder === 1) {
      if (req.user.managerId !== actorUserId) {
        throw new ForbiddenException('Not the team lead for this employee');
      }
    } else if (req.currentStepOrder === 2) {
      if (req.user.manager?.managerId !== actorUserId) {
        throw new ForbiddenException('Not the manager for this employee');
      }
    } else if (req.currentStepOrder === 3) {
      if (actorRole !== 'hr' && actorRole !== 'hrAdmin') {
        throw new ForbiddenException('Not HR Admin');
      }
    }

    const pendingStep = req.approvalSteps.find(
      (s) => s.stepOrder === req.currentStepOrder,
    );
    if (!pendingStep) throw new NotFoundException('Active step not found');

    await this.prisma.leaveApprovalStep.update({
      where: { id: pendingStep.id },
      data: { status: 'approved', timestamp: new Date() },
    });

    const isLast = req.currentStepOrder === 3;
    const newStatus = isLast ? 'approved' : 'pending';
    const nextStepOrder = isLast
      ? req.currentStepOrder
      : req.currentStepOrder + 1;

    const updated = await this.prisma.leaveRequest.update({
      where: { id },
      data: {
        overallStatus: newStatus,
        currentStepOrder: nextStepOrder,
      },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: { include: { manager: true } },
      },
    });

    this.events.emitToUser(req.userId, 'updated', updated);

    const empToken = updated.user?.fcmToken;
    if (empToken) {
      if (newStatus === 'approved') {
        this.notifications.notifyLeaveApproved(
          empToken,
          updated.user.name,
          updated.id,
        );
      } else {
        this.notifications.sendToDevice({
          token: empToken,
          title: '⏳ جاري مراجعة طلبك',
          body: `مرحباً ${updated.user.name}، تمت الموافقة على خطوة وطلبك في انتظار الموافقة التالية`,
          data: { type: 'leave_step_approved', id: updated.id },
        });
      }
    }

    return updated;
  }

  async rejectRequest(id: string, actorUserId: string, actorRole: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: { include: { manager: true } },
      },
    });

    if (!req) throw new NotFoundException('Leave request not found');
    if (req.overallStatus !== 'pending') {
      throw new ForbiddenException('Request is not pending');
    }

    // Authorization checks
    if (req.currentStepOrder === 1) {
      if (req.user.managerId !== actorUserId) {
        throw new ForbiddenException('Not the team lead for this employee');
      }
    } else if (req.currentStepOrder === 2) {
      if (req.user.manager?.managerId !== actorUserId) {
        throw new ForbiddenException('Not the manager for this employee');
      }
    } else if (req.currentStepOrder === 3) {
      if (actorRole !== 'hr' && actorRole !== 'hrAdmin') {
        throw new ForbiddenException('Not HR Admin');
      }
    }

    const pendingStep = req.approvalSteps.find(
      (s) => s.stepOrder === req.currentStepOrder,
    );
    if (pendingStep) {
      await this.prisma.leaveApprovalStep.update({
        where: { id: pendingStep.id },
        data: { status: 'rejected', timestamp: new Date() },
      });
    }

    const updated = await this.prisma.leaveRequest.update({
      where: { id },
      data: { overallStatus: 'rejected' },
      include: {
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: true,
      },
    });

    this.events.emitToUser(req.userId, 'updated', updated);

    const empToken = updated.user?.fcmToken;
    if (empToken) {
      this.notifications.notifyLeaveRejected(
        empToken,
        updated.user.name,
        updated.id,
      );
    }

    return updated;
  }
}
