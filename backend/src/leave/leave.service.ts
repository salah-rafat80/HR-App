import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';
import { mockFcmTokens } from '../auth/auth.service';

// Module-level singleton — survives NestJS hot-reload (not wiped on file change)
const globalInMemoryRequests = new Map<string, any[]>();

@Injectable()
export class LeaveService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
    private notifications: NotificationService,
  ) {}

  async getBalances(userId: string) {
    try {
      return await this.prisma.leaveBalance.findMany({
        where: { userId },
      });
    } catch (e) {
      console.warn('Database offline, returning fallback leave balances');
      return [
        { id: 'b1', userId, type: 'annual', daysUsed: 6, daysTotal: 21 },
        { id: 'b2', userId, type: 'sick', daysUsed: 4, daysTotal: 14 },
        { id: 'b3', userId, type: 'emergency', daysUsed: 1, daysTotal: 3 },
      ];
    }
  }

  async getMyRequests(userId: string) {
    try {
      return await this.prisma.leaveRequest.findMany({
        where: { userId },
        include: { 
          approvalSteps: { orderBy: { stepOrder: 'asc' } }, 
          user: true 
        },
        orderBy: { createdAt: 'desc' },
      });
    } catch (e) {
      console.warn('Database offline, returning fallback my-requests');
      return globalInMemoryRequests.get(userId) || [];
    }
  }


  async applyLeave(userId: string, data: any) {
    let request: any;
    try {
      request = await this.prisma.leaveRequest.create({
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
              { stepName: 'team_lead', status: 'pending', stepOrder: 1, timestamp: new Date() },
              { stepName: 'manager', status: 'pending', stepOrder: 2, timestamp: new Date() },
              { stepName: 'hr', status: 'pending', stepOrder: 3, timestamp: new Date() },
            ]
          }
        },
        include: { 
          approvalSteps: { orderBy: { stepOrder: 'asc' } }, 
          user: true 
        },
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
    } catch (e) {
      console.warn('Database offline, returning fallback leave request');
      request = {
        id: 'mock_req_' + Date.now(),
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
        approvalSteps: [
          { stepName: 'team_lead', status: 'pending', stepOrder: 1, timestamp: new Date() },
          { stepName: 'manager', status: 'pending', stepOrder: 2, timestamp: new Date() },
          { stepName: 'hr', status: 'pending', stepOrder: 3, timestamp: new Date() },
        ],
        user: { id: userId, name: 'Mock User', managerId: 'mock_manager' }
      };

      const existing = globalInMemoryRequests.get(userId) || [];
      existing.unshift(request);
      globalInMemoryRequests.set(userId, existing);
    }

    // Notify the employee
    this.events.emitToUser(userId, 'created', request);
    // Notify all team_lead admins on web portal so their list auto-refreshes
    this.events.emitToRole('team_lead', 'created', request);
    this.events.emitToRole('manager', 'created', request);
    this.events.emitToRole('hr', 'created', request);
    this.events.emitToRole('hrAdmin', 'created', request);
    // Notify the team lead specifically
    if (request.user.managerId) {
      this.events.emitToUser(request.user.managerId, 'created', request);
      
      let managerToken: string | undefined = undefined;
      try {
        const manager = await this.prisma.user.findUnique({ where: { id: request.user.managerId } });
        if (manager?.fcmToken) managerToken = manager.fcmToken;
      } catch(e) {}

      // Fallback for mock db
      managerToken = managerToken || mockFcmTokens[request.user.managerId.replace('mock_', '')];

      if (managerToken) {
        this.notifications.notifyNewLeaveRequest(managerToken, request.user.name);
      }
    }

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

  async getPendingApprovals(role: string, actorUserId: string) {
    // For demo: team_lead sees all step-1, manager sees all step-2, hr sees all step-3
    // Remove hierarchy checks that require real DB user relationships
    let stepOrder: number | null = null;

    if (role === 'hr' || role === 'hrAdmin') {
      stepOrder = 3;
    } else if (role === 'team_lead') {
      stepOrder = 1;
    } else if (role === 'manager') {
      stepOrder = 2;
    } else {
      return []; // other roles don't approve
    }

    try {
      const dbResults = await this.prisma.leaveRequest.findMany({
        where: { overallStatus: 'pending', currentStepOrder: stepOrder },
        include: { 
          approvalSteps: { orderBy: { stepOrder: 'asc' } }, 
          user: true 
        },
        orderBy: { createdAt: 'desc' },
      });

      // Merge in-memory requests for demo mode
      const allMemoryRequests: any[] = [];
      for (const [, reqs] of globalInMemoryRequests) {
        allMemoryRequests.push(...reqs);
      }
      const memoryPending = allMemoryRequests.filter(r => 
        r.overallStatus === 'pending' && r.currentStepOrder === stepOrder
      );

      // Avoid duplicates
      const dbIds = new Set(dbResults.map((r: any) => r.id));
      const uniqueMemory = memoryPending.filter(r => !dbIds.has(r.id));
      return [...dbResults, ...uniqueMemory];
    } catch (e) {
      console.warn('Database offline, returning in-memory pending approvals');
      const allMemoryRequests: any[] = [];
      for (const [, reqs] of globalInMemoryRequests) {
        allMemoryRequests.push(...reqs);
      }
      return allMemoryRequests.filter(r => 
        r.overallStatus === 'pending' && r.currentStepOrder === stepOrder
      );
    }
  }

  async approveRequest(id: string, actorUserId: string, actorRole: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: { 
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: { include: { manager: true } }
      },
    });

    if (!req) throw new NotFoundException();
    if (req.overallStatus !== 'pending') throw new ForbiddenException('Request is not pending');

    // Authorization
    if (req.currentStepOrder === 1) {
      if (req.user.managerId !== actorUserId) throw new ForbiddenException('Not the team lead for this employee');
    } else if (req.currentStepOrder === 2) {
      if (req.user.manager?.managerId !== actorUserId) throw new ForbiddenException('Not the manager for this employee');
    } else if (req.currentStepOrder === 3) {
      if (actorRole !== 'hr' && actorRole !== 'hrAdmin') throw new ForbiddenException('Not HR Admin');
    }

    const pendingStep = req.approvalSteps.find(s => s.stepOrder === req.currentStepOrder);
    if (!pendingStep) throw new NotFoundException('Active step not found');

    await this.prisma.leaveApprovalStep.update({
      where: { id: pendingStep.id },
      data: { status: 'approved', timestamp: new Date() },
    });

    const isLast = req.currentStepOrder === 3;
    const newStatus = isLast ? 'approved' : 'pending';
    const nextStepOrder = isLast ? req.currentStepOrder : req.currentStepOrder + 1;

    const updated = await this.prisma.leaveRequest.update({
      where: { id },
      data: { 
        overallStatus: newStatus,
        currentStepOrder: nextStepOrder,
      },
      include: { 
        approvalSteps: { orderBy: { stepOrder: 'asc' } }, 
        user: { include: { manager: true } }
      },
    });

    // Targeted Events
    this.events.emitToUser(req.userId, 'updated', updated); // Notify employee

    // Push notification to employee
    const empToken = updated.user?.fcmToken || mockFcmTokens[updated.user.email];
    if (empToken && newStatus === 'approved') {
      this.notifications.notifyLeaveApproved(empToken, updated.user.name);
    }
    
    // Notify next approver
    if (!isLast) {
      if (nextStepOrder === 2 && updated.user.manager?.managerId) {
        this.events.emitToUser(updated.user.manager.managerId, 'updated', updated);
      } else if (nextStepOrder === 3) {
        this.events.emitToRole('hr', 'updated', updated);
      }
    }

    return updated;
  }

  async rejectRequest(id: string, actorUserId: string, actorRole: string) {
    const req = await this.prisma.leaveRequest.findUnique({
      where: { id },
      include: { 
        approvalSteps: { orderBy: { stepOrder: 'asc' } },
        user: { include: { manager: true } }
      },
    });

    if (!req) throw new NotFoundException();
    if (req.overallStatus !== 'pending') throw new ForbiddenException('Request is not pending');

    // Authorization
    if (req.currentStepOrder === 1) {
      if (req.user.managerId !== actorUserId) throw new ForbiddenException('Not the team lead for this employee');
    } else if (req.currentStepOrder === 2) {
      if (req.user.manager?.managerId !== actorUserId) throw new ForbiddenException('Not the manager for this employee');
    } else if (req.currentStepOrder === 3) {
      if (actorRole !== 'hr' && actorRole !== 'hrAdmin') throw new ForbiddenException('Not HR Admin');
    }

    const pendingStep = req.approvalSteps.find(s => s.stepOrder === req.currentStepOrder);
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
        user: true 
      },
    });

    this.events.emitToUser(req.userId, 'updated', updated);
    
    // Push notification to employee
    const empToken = updated.user?.fcmToken || mockFcmTokens[updated.user.email];
    if (empToken) {
      this.notifications.notifyLeaveRejected(empToken, updated.user.name);
    }
    
    return updated;
  }
}
