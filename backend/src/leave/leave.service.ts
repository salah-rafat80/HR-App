/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call */
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';
import { CreateLeaveRequestDto } from './dto/create-leave-request.dto';
import { CreateLeavePolicyDto } from './dto/create-leave-policy.dto';
import { UpdateLeavePolicyDto } from './dto/update-leave-policy.dto';
import { CreateLeaveBalanceDto } from './dto/create-leave-balance.dto';
import { AdjustLeaveBalanceDto } from './dto/adjust-leave-balance.dto';
import { ApprovalActionDto } from './dto/approval-action.dto';
import { CancelLeaveRequestDto } from './dto/cancel-leave-request.dto';

import { CompanyTimeService } from '../common/time/company-time.service';
import { LeaveCalendarService } from './leave-calendar.service';
import { Prisma, LeaveType } from '@prisma/client';
import { DateTime } from 'luxon';

@Injectable()
export class LeaveService {
  private readonly logger = new Logger(LeaveService.name);

  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
    private notifications: NotificationService,
    private companyTime: CompanyTimeService,
    private calendar: LeaveCalendarService,
  ) {}

  /**
   * Helper to safely construct a Prisma.Decimal from string or number.
   */
  private toDecimal(val: string | number | Prisma.Decimal): Prisma.Decimal {
    if (val instanceof Prisma.Decimal) return val;
    return new Prisma.Decimal(val.toString());
  }

  private projectLeaveRequest(req: any): any {
    if (!req) return null;
    const safeUser = req.user
      ? {
          id: req.user.id,
          name: req.user.name,
          employeeCode: req.user.employeeCode,
          department: req.user.department,
          branchId: req.user.branchId,
          role: req.user.role,
        }
      : undefined;

    const safeSteps =
      req.approvalSteps && Array.isArray(req.approvalSteps)
        ? req.approvalSteps.map((step: any) => {
            const safeApprover = step.expectedApprover
              ? {
                  id: step.expectedApprover.id,
                  name: step.expectedApprover.name,
                  employeeCode: step.expectedApprover.employeeCode,
                  department: step.expectedApprover.department,
                  branchId: step.expectedApprover.branchId,
                  role: step.expectedApprover.role,
                }
              : null;
            return {
              id: step.id,
              requestId: step.requestId,
              stepName: step.stepName,
              status: step.status,
              stepOrder: step.stepOrder,
              timestamp: step.timestamp,
              expectedApproverId: step.expectedApproverId,
              expectedApprover: safeApprover,
            };
          })
        : undefined;

    return {
      id: req.id,
      userId: req.userId,
      type: req.type,
      startDate: req.startDate,
      endDate: req.endDate,
      isHalfDay: req.isHalfDay,
      halfDayPeriod: req.halfDayPeriod,
      reason: req.reason,
      hasAttachment: req.hasAttachment,
      overallStatus: req.overallStatus,
      currentStepOrder: req.currentStepOrder,
      workingDays: req.workingDays,
      createdAt: req.createdAt,
      updatedAt: req.updatedAt,
      approvalSteps: safeSteps,
      user: safeUser,
    };
  }

  /**
   * Safe transaction wrapper with retry for serialization errors (P2034)
   */
  private async runTransaction<T>(
    actions: (tx: Prisma.TransactionClient) => Promise<T>,
    retries = 3,
    delayMs = 100,
  ): Promise<T> {
    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            return await actions(tx);
          },
          {
            isolationLevel: 'Serializable',
          },
        );
      } catch (error) {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2034' &&
          attempt < retries
        ) {
          this.logger.warn(
            `Serializable transaction failed (P2034), retrying attempt ${attempt}...`,
          );
          await new Promise((resolve) =>
            setTimeout(resolve, delayMs * Math.pow(2, attempt)),
          );
          continue;
        }
        throw error;
      }
    }
    throw new Error('Transaction failed after maximum retries');
  }

  // ==========================================
  // HR Leave Policies Administration
  // ==========================================

  async getPolicies(includeInactive = true) {
    return this.prisma.leavePolicy.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: { type: 'asc' },
    });
  }

  async createPolicy(actorUserId: string, data: CreateLeavePolicyDto) {
    const existing = await this.prisma.leavePolicy.findUnique({
      where: { type: data.type },
    });
    if (existing) {
      throw new ConflictException('POLICY_ALREADY_EXISTS');
    }

    const entitlement = this.toDecimal(data.annualEntitlement);

    const policy = await this.prisma.leavePolicy.create({
      data: {
        type: data.type,
        displayNameAr: data.displayNameAr,
        annualEntitlement: entitlement,
        isPaid: data.isPaid ?? true,
        requiresBalance: data.requiresBalance ?? true,
        allowHalfDay: data.allowHalfDay ?? true,
        minimumNoticeDays: data.minimumNoticeDays ?? 0,
        requiresReason: data.requiresReason ?? true,
        isActive: data.isActive ?? true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        actorUserId,
        action: 'CREATE_LEAVE_POLICY',
        targetType: 'LeavePolicy',
        targetId: policy.id,
        metadata: {
          type: policy.type,
          annualEntitlement: policy.annualEntitlement.toString(),
        },
      },
    });

    return policy;
  }

  async updatePolicy(
    actorUserId: string,
    type: LeaveType,
    data: UpdateLeavePolicyDto,
  ) {
    const policy = await this.prisma.leavePolicy.findUnique({
      where: { type },
    });
    if (!policy) {
      throw new NotFoundException('POLICY_NOT_FOUND');
    }

    const updateData: Prisma.LeavePolicyUpdateInput = { ...data };
    if (data.annualEntitlement !== undefined) {
      updateData.annualEntitlement = this.toDecimal(data.annualEntitlement);
    }

    const updated = await this.prisma.leavePolicy.update({
      where: { type },
      data: updateData,
    });

    await this.prisma.auditLog.create({
      data: {
        actorUserId,
        action: 'UPDATE_LEAVE_POLICY',
        targetType: 'LeavePolicy',
        targetId: updated.id,
        metadata: { type, changes: data as any },
      },
    });

    return updated;
  }

  async togglePolicy(actorUserId: string, type: LeaveType) {
    const policy = await this.prisma.leavePolicy.findUnique({
      where: { type },
    });
    if (!policy) {
      throw new NotFoundException('POLICY_NOT_FOUND');
    }

    const updated = await this.prisma.leavePolicy.update({
      where: { type },
      data: { isActive: !policy.isActive },
    });

    await this.prisma.auditLog.create({
      data: {
        actorUserId,
        action: 'TOGGLE_LEAVE_POLICY',
        targetType: 'LeavePolicy',
        targetId: updated.id,
        metadata: { type, isActive: updated.isActive },
      },
    });

    return updated;
  }

  // ==========================================
  // HR Leave Balances Administration
  // ==========================================

  async getBalances(userId: string) {
    return this.prisma.leaveBalance.findMany({
      where: { userId },
      include: { adjustments: true },
    });
  }

  async getBalancesAdmin(
    page: number,
    limit: number,
    employeeId?: string,
    department?: string,
    branchId?: string,
    year?: number,
  ) {
    const safeLimit = Math.min(100, Math.max(1, limit || 10));
    const skip = (Math.max(1, page || 1) - 1) * safeLimit;

    const where: Prisma.LeaveBalanceWhereInput = {};
    if (employeeId) where.userId = employeeId;
    if (year) where.year = year;

    if (department || branchId) {
      where.user = {
        is: {
          department: department ? { equals: department } : undefined,
          branchId: branchId ? { equals: branchId } : undefined,
        },
      };
    }

    const [total, items] = await Promise.all([
      this.prisma.leaveBalance.count({ where }),
      this.prisma.leaveBalance.findMany({
        where,
        select: {
          id: true,
          userId: true,
          type: true,
          daysUsed: true,
          daysTotal: true,
          year: true,
          entitledDays: true,
          adjustmentDays: true,
          reservedDays: true,
          usedDays: true,
          adjustments: {
            select: {
              id: true,
              balanceId: true,
              adjustmentDays: true,
              reason: true,
              createdAt: true,
            },
          },
          user: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
        orderBy: [{ year: 'desc' }, { type: 'asc' }],
        skip,
        take: safeLimit,
      }),
    ]);

    return {
      total,
      page,
      limit: safeLimit,
      totalPages: Math.ceil(total / safeLimit),
      items,
    };
  }

  async createBalance(actorUserId: string, data: CreateLeaveBalanceDto) {
    return this.runTransaction(async (tx) => {
      const existing = await tx.leaveBalance.findFirst({
        where: {
          userId: data.userId,
          type: data.type,
          year: data.year,
        },
      });

      if (existing) {
        throw new ConflictException('BALANCE_ALREADY_EXISTS');
      }

      const entitlement = this.toDecimal(data.entitledDays);

      const balance = await tx.leaveBalance.create({
        data: {
          userId: data.userId,
          type: data.type,
          year: data.year,
          entitledDays: entitlement,
          daysTotal: 0, // safe compatibility default required by schema
          daysUsed: 0, // safe compatibility default required by schema
        },
      });

      await tx.auditLog.create({
        data: {
          actorUserId,
          action: 'CREATE_LEAVE_BALANCE',
          targetType: 'LeaveBalance',
          targetId: balance.id,
          metadata: {
            userId: data.userId,
            type: data.type,
            year: data.year,
            entitledDays: data.entitledDays,
          },
        },
      });

      return balance;
    });
  }

  async adjustBalance(
    actorUserId: string,
    id: string,
    data: AdjustLeaveBalanceDto,
  ) {
    if (!data.reason || data.reason.trim().length === 0) {
      throw new BadRequestException('REASON_REQUIRED');
    }

    return this.runTransaction(async (tx) => {
      const balance = await tx.leaveBalance.findUnique({
        where: { id },
      });
      if (!balance) {
        throw new NotFoundException('BALANCE_NOT_FOUND');
      }

      const currentAdjustment = this.toDecimal(balance.adjustmentDays ?? 0);
      const diff = this.toDecimal(data.adjustmentDays);
      const newAdjustment = currentAdjustment.plus(diff);

      const entitled = this.toDecimal(balance.entitledDays ?? 0);
      const reserved = this.toDecimal(balance.reservedDays ?? 0);
      const used = this.toDecimal(balance.usedDays ?? 0);

      // Check for negative available state
      const totalAvailable = entitled
        .plus(newAdjustment)
        .minus(reserved)
        .minus(used);
      if (totalAvailable.lt(0)) {
        throw new BadRequestException('INVALID_BALANCE_STATE');
      }

      const updated = await tx.leaveBalance.update({
        where: { id },
        data: {
          adjustmentDays: newAdjustment,
          adjustments: {
            create: {
              adjustmentDays: diff,
              reason: data.reason,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          actorUserId,
          action: 'ADJUST_LEAVE_BALANCE',
          targetType: 'LeaveBalance',
          targetId: id,
          metadata: {
            adjustmentDays: data.adjustmentDays,
            reason: data.reason,
          },
        },
      });

      return updated;
    });
  }

  // ==========================================
  // Company Leave Approval Configuration
  // ==========================================

  async getCompanyApprovalConfig() {
    const config =
      await this.prisma.companyLeaveApprovalConfiguration.findUnique({
        where: { id: 'default' },
        select: {
          id: true,
          finalHrApproverId: true,
          finalHrApprover: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
      });
    if (!config) {
      return {
        configured: false,
        id: null,
        finalHrApproverId: null,
        finalHrApprover: null,
      };
    }
    return { ...config, configured: true };
  }

  async updateCompanyApprovalConfig(
    actorUserId: string,
    finalHrApproverId: string | null,
  ) {
    if (finalHrApproverId) {
      const hrUser = await this.prisma.user.findUnique({
        where: { id: finalHrApproverId },
      });
      if (!hrUser || !hrUser.isActive) {
        throw new BadRequestException('INVALID_HR_APPROVER_USER');
      }
      if (
        hrUser.role !== 'hr' &&
        hrUser.role !== 'hrAdmin' &&
        hrUser.role !== 'superAdmin'
      ) {
        throw new BadRequestException('INVALID_HR_APPROVER_ROLE');
      }
    }

    const config = await this.prisma.companyLeaveApprovalConfiguration.upsert({
      where: { id: 'default' },
      update: { finalHrApproverId },
      create: { id: 'default', finalHrApproverId },
    });

    await this.prisma.auditLog.create({
      data: {
        actorUserId,
        action: 'UPDATE_COMPANY_LEAVE_APPROVAL_CONFIG',
        targetType: 'CompanyLeaveApprovalConfiguration',
        targetId: config.id,
        metadata: { finalHrApproverId },
      },
    });

    const result =
      await this.prisma.companyLeaveApprovalConfiguration.findUnique({
        where: { id: config.id },
        select: {
          id: true,
          finalHrApproverId: true,
          finalHrApprover: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
      });
    return { ...result, configured: true };
  }

  async getEmployeesForPicker() {
    return this.prisma.user.findMany({
      where: { isActive: true },
      select: {
        id: true,
        name: true,
        employeeCode: true,
        department: true,
        branchId: true,
        role: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  // ==========================================
  // Employee Leave Actions
  // ==========================================

  async getMyRequests(userId: string) {
    const requests = await this.prisma.leaveRequest.findMany({
      where: { userId },
      select: {
        id: true,
        userId: true,
        type: true,
        startDate: true,
        endDate: true,
        isHalfDay: true,
        halfDayPeriod: true,
        reason: true,
        hasAttachment: true,
        overallStatus: true,
        currentStepOrder: true,
        workingDays: true,
        createdAt: true,
        updatedAt: true,
        approvalSteps: {
          orderBy: { stepOrder: 'asc' },
          select: {
            id: true,
            requestId: true,
            stepName: true,
            status: true,
            stepOrder: true,
            timestamp: true,
            expectedApproverId: true,
            expectedApprover: {
              select: {
                id: true,
                name: true,
                employeeCode: true,
                department: true,
                branchId: true,
                role: true,
              },
            },
          },
        },
        user: {
          select: {
            id: true,
            name: true,
            employeeCode: true,
            department: true,
            branchId: true,
            role: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return requests.map((r) => this.projectLeaveRequest(r));
  }

  /**
   * Server-backed preflight leave preview endpoint.
   */
  async previewLeave(userId: string, data: CreateLeaveRequestDto) {
    const policy = await this.prisma.leavePolicy.findUnique({
      where: { type: data.type },
    });
    if (!policy || !policy.isActive) {
      throw new BadRequestException('POLICY_NOT_FOUND_OR_INACTIVE');
    }

    const workingDays = await this.calendar.calculateWorkingDays(
      data.startDate,
      data.endDate,
      data.isHalfDay,
    );

    let isSufficient = true;
    let availableDaysStr = '0';

    if (policy.requiresBalance) {
      const year = this.companyTime.companyBusinessYear(data.startDate);
      const balance = await this.prisma.leaveBalance.findFirst({
        where: { userId, type: data.type, year },
      });

      if (!balance) {
        isSufficient = false;
      } else {
        const entitled = this.toDecimal(balance.entitledDays ?? 0);
        const adjustment = this.toDecimal(balance.adjustmentDays ?? 0);
        const reserved = this.toDecimal(balance.reservedDays ?? 0);
        const used = this.toDecimal(balance.usedDays ?? 0);
        const available = entitled.plus(adjustment).minus(reserved).minus(used);
        availableDaysStr = available.toString();
        isSufficient = available.gte(workingDays);
      }
    }

    return {
      workingDays: workingDays.toString(),
      isSufficient,
      availableDays: availableDaysStr,
      requiresBalance: policy.requiresBalance,
    };
  }

  async applyLeave(userId: string, data: CreateLeaveRequestDto) {
    // 1. Fetch config and check if configured
    const config =
      await this.prisma.companyLeaveApprovalConfiguration.findUnique({
        where: { id: 'default' },
      });
    if (!config || !config.finalHrApproverId) {
      throw new BadRequestException('MISSING_FINAL_HR_APPROVER');
    }
    const finalHrApproverId = config.finalHrApproverId;

    // 2. Fetch requester and check approval chain roles
    const requester = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        employeeCode: true,
        department: true,
        branchId: true,
        role: true,
        isActive: true,
        managerId: true,
        manager: {
          select: {
            id: true,
            name: true,
            role: true,
            isActive: true,
            department: true,
            managerId: true,
            manager: {
              select: {
                id: true,
                name: true,
                role: true,
                isActive: true,
                department: true,
              },
            },
          },
        },
      },
    });
    if (!requester) {
      throw new NotFoundException('EMPLOYEE_NOT_FOUND');
    }

    // Requester role hr, hrAdmin, superAdmin do not permit self-approval
    if (
      requester.role === 'hr' ||
      requester.role === 'hrAdmin' ||
      requester.role === 'superAdmin'
    ) {
      throw new BadRequestException('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
    }

    // Resolve approval hierarchy
    const stepsToCreate: {
      stepName: string;
      stepOrder: number;
      expectedApproverId: string;
    }[] = [];

    if (requester.role === 'employee') {
      const tl = requester.manager;
      if (
        !tl ||
        tl.role !== 'team_lead' ||
        tl.department !== requester.department
      ) {
        throw new BadRequestException('MISSING_TEAM_LEAD_APPROVER');
      }

      const mgr = tl.manager;
      if (!mgr || mgr.role !== 'manager') {
        throw new BadRequestException('MISSING_MANAGER_APPROVER');
      }

      if (
        finalHrApproverId === userId ||
        finalHrApproverId === tl.id ||
        finalHrApproverId === mgr.id
      ) {
        // Prevent duplicate persons in chain that lead to bypasses or self-approval
        throw new BadRequestException('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
      }

      stepsToCreate.push(
        { stepName: 'team_lead', stepOrder: 1, expectedApproverId: tl.id },
        { stepName: 'manager', stepOrder: 2, expectedApproverId: mgr.id },
        { stepName: 'hr', stepOrder: 3, expectedApproverId: finalHrApproverId },
      );
    } else if (requester.role === 'team_lead') {
      const mgr = requester.manager;
      if (!mgr || mgr.role !== 'manager') {
        throw new BadRequestException('MISSING_MANAGER_APPROVER');
      }

      if (finalHrApproverId === userId || finalHrApproverId === mgr.id) {
        throw new BadRequestException('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
      }

      stepsToCreate.push(
        { stepName: 'manager', stepOrder: 2, expectedApproverId: mgr.id },
        { stepName: 'hr', stepOrder: 3, expectedApproverId: finalHrApproverId },
      );
    } else if (requester.role === 'manager') {
      if (finalHrApproverId === userId) {
        throw new BadRequestException('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
      }

      stepsToCreate.push({
        stepName: 'hr',
        stepOrder: 3,
        expectedApproverId: finalHrApproverId,
      });
    } else {
      throw new BadRequestException('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
    }

    // Determine initial currentStepOrder
    const initialStepOrder = stepsToCreate[0].stepOrder;

    // 3. Begin Serializable Transaction
    let result: any = null;
    let nextApproverId: string | null = null;
    const requesterName = requester.name;

    await this.runTransaction(async (tx) => {
      // Fetch active policy
      const policy = await tx.leavePolicy.findUnique({
        where: { type: data.type },
      });
      if (!policy || !policy.isActive) {
        throw new BadRequestException('POLICY_NOT_FOUND_OR_INACTIVE');
      }

      const todayStr = this.companyTime.companyBusinessDate();
      if (data.startDate < todayStr) {
        throw new BadRequestException('START_DATE_BEFORE_TODAY');
      }

      // Check notice days
      const startDt = DateTime.fromISO(data.startDate, {
        zone: 'Africa/Cairo',
      }).startOf('day');
      const todayDt = DateTime.fromISO(todayStr, {
        zone: 'Africa/Cairo',
      }).startOf('day');
      const diffDays = Math.floor(startDt.diff(todayDt, 'days').days);
      if (diffDays < policy.minimumNoticeDays) {
        throw new BadRequestException('MINIMUM_NOTICE_NOT_MET');
      }

      // Check reason requirements
      if (
        policy.requiresReason &&
        (!data.reason || data.reason.trim().length === 0)
      ) {
        throw new BadRequestException('REASON_REQUIRED');
      }

      // Calculate working days
      const workingDays = await this.calendar.calculateWorkingDays(
        data.startDate,
        data.endDate,
        data.isHalfDay,
      );
      if (workingDays.equals(0)) {
        throw new BadRequestException('NO_WORKING_DAYS_IN_RANGE');
      }

      // Check overlapping requests
      const startObj = new Date(data.startDate);
      const endObj = new Date(data.endDate);

      const overlap = await tx.leaveRequest.findFirst({
        where: {
          userId,
          overallStatus: { in: ['pending', 'approved'] },
          startDate: { lte: endObj },
          endDate: { gte: startObj },
        },
      });
      if (overlap) {
        throw new BadRequestException('LEAVE_OVERLAP');
      }

      // Check attendance conflicts
      // Generate working date list
      const conflictDates: Date[] = [];
      let cur = startDt;
      const finalEnd = DateTime.fromISO(data.endDate, {
        zone: 'Africa/Cairo',
      }).startOf('day');
      while (cur <= finalEnd) {
        // Only working days are conflicts
        const isFri = cur.weekday === 5;
        const hol = await tx.companyHoliday.findFirst({
          where: { isActive: true, date: cur.toJSDate() },
        });
        if (!isFri && !hol) {
          conflictDates.push(cur.toJSDate());
        }
        cur = cur.plus({ days: 1 });
      }

      if (conflictDates.length > 0) {
        const attendanceConflict = await tx.attendanceRecord.findFirst({
          where: {
            userId,
            date: { in: conflictDates },
          },
        });
        if (attendanceConflict) {
          throw new BadRequestException('ATTENDANCE_CONFLICT');
        }
      }

      // Check and update balance
      if (policy.requiresBalance) {
        const year = startDt.year;
        const balance = await tx.leaveBalance.findFirst({
          where: { userId, type: data.type, year },
        });
        if (!balance) {
          throw new BadRequestException('LEAVE_BALANCE_NOT_FOUND');
        }

        const entitled = this.toDecimal(balance.entitledDays ?? 0);
        const adjustment = this.toDecimal(balance.adjustmentDays ?? 0);
        const reserved = this.toDecimal(balance.reservedDays ?? 0);
        const used = this.toDecimal(balance.usedDays ?? 0);
        const available = entitled.plus(adjustment).minus(reserved).minus(used);

        if (available.lt(workingDays)) {
          throw new BadRequestException('INSUFFICIENT_LEAVE_BALANCE');
        }

        // Reserve days
        const newReserved = reserved.plus(workingDays);
        if (newReserved.lt(0)) {
          throw new BadRequestException('INVALID_BALANCE_STATE');
        }

        await tx.leaveBalance.update({
          where: { id: balance.id },
          data: { reservedDays: newReserved },
        });
      }

      // Create request and steps
      const now = this.companyTime.serverNowUtc();

      const created = await tx.leaveRequest.create({
        data: {
          userId,
          type: data.type,
          startDate: startObj,
          endDate: endObj,
          isHalfDay: data.isHalfDay,
          halfDayPeriod: data.halfDayPeriod || null,
          reason: data.reason,
          workingDays,
          overallStatus: 'pending',
          currentStepOrder: initialStepOrder,
          hasAttachment: false, // Explicitly false per rule E-5
          approvalSteps: {
            create: stepsToCreate.map((s) => ({
              stepName: s.stepName,
              stepOrder: s.stepOrder,
              status: 'pending',
              expectedApproverId: s.expectedApproverId,
              timestamp: now,
            })),
          },
        },
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
              expectedApprover: {
                select: {
                  id: true,
                  name: true,
                  employeeCode: true,
                  department: true,
                  branchId: true,
                  role: true,
                },
              },
            },
          },
          user: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
      });

      result = this.projectLeaveRequest(created);
      nextApproverId = stepsToCreate[0].expectedApproverId;
    });

    // 4. Post-commit notifications
    this.events.emitToUser(userId, 'created', result);
    if (nextApproverId) {
      this.events.emitToUser(nextApproverId, 'created', result);
      const approver = await this.prisma.user.findUnique({
        where: { id: nextApproverId },
        select: { fcmToken: true },
      });
      if (approver?.fcmToken) {
        void this.notifications
          .notifyNewLeaveRequest(nextApproverId, approver.fcmToken, requesterName, result.id)
          .catch(() => undefined);
      }
    }

    return result;
  }

  async cancelRequest(
    id: string,
    actorUserId: string,
    data: CancelLeaveRequestDto,
  ) {
    if (!data.reason || data.reason.trim().length === 0) {
      throw new BadRequestException('REASON_REQUIRED');
    }

    let result: any = null;
    let ownerId = '';

    await this.runTransaction(async (tx) => {
      const req = await tx.leaveRequest.findUnique({
        where: { id },
        select: {
          id: true,
          userId: true,
          overallStatus: true,
          startDate: true,
          endDate: true,
          type: true,
          workingDays: true,
        },
      });
      if (!req) {
        throw new NotFoundException('LEAVE_REQUEST_NOT_FOUND');
      }

      ownerId = req.userId;

      // Access checks: only request owner or HR can cancel
      const actor = await tx.user.findUnique({ where: { id: actorUserId } });
      const isOwner = req.userId === actorUserId;
      const isHr =
        actor && ['hr', 'hrAdmin', 'superAdmin'].includes(actor.role);
      if (!isOwner && !isHr) {
        throw new ForbiddenException('UNAUTHORIZED');
      }

      // Reject already closed requests
      if (
        req.overallStatus === 'rejected' ||
        req.overallStatus === 'cancelled'
      ) {
        throw new BadRequestException('REQUEST_ALREADY_CLOSED');
      }

      const todayStr = this.companyTime.companyBusinessDate();
      const startStr = this.companyTime.companyBusinessDate(req.startDate);

      if (isOwner) {
        // Employees can only cancel pending or approved requests that start in the future
        if (startStr < todayStr) {
          throw new BadRequestException('CANNOT_CANCEL_PAST_LEAVE');
        }
      }

      // Fetch active policy
      const policy = await tx.leavePolicy.findUnique({
        where: { type: req.type },
      });
      const requiresBalance = policy ? policy.requiresBalance : true;

      if (req.overallStatus === 'pending') {
        // Pending: release reservedDays
        if (requiresBalance) {
          const year = DateTime.fromJSDate(req.startDate).year;
          const balance = await tx.leaveBalance.findFirst({
            where: { userId: req.userId, type: req.type, year },
          });
          if (balance) {
            const reserved = this.toDecimal(balance.reservedDays ?? 0);
            const workingDays = this.toDecimal(req.workingDays ?? 0);
            const newReserved = reserved.minus(workingDays);
            if (newReserved.lt(0)) {
              throw new BadRequestException('INVALID_BALANCE_STATE');
            }

            await tx.leaveBalance.update({
              where: { id: balance.id },
              data: { reservedDays: newReserved },
            });
          }
        }
      } else if (req.overallStatus === 'approved') {
        // Approved: release usedDays (since it transferred reserved -> used at final approval)
        if (requiresBalance) {
          const year = DateTime.fromJSDate(req.startDate).year;
          const balance = await tx.leaveBalance.findFirst({
            where: { userId: req.userId, type: req.type, year },
          });
          if (balance) {
            const used = this.toDecimal(balance.usedDays ?? 0);
            const workingDays = this.toDecimal(req.workingDays ?? 0);
            const newUsed = used.minus(workingDays);
            if (newUsed.lt(0)) {
              throw new BadRequestException('INVALID_BALANCE_STATE');
            }

            await tx.leaveBalance.update({
              where: { id: balance.id },
              data: { usedDays: newUsed },
            });
          }
        }
      }

      const updated = await tx.leaveRequest.update({
        where: { id },
        data: { overallStatus: 'cancelled' },
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
              expectedApprover: {
                select: {
                  id: true,
                  name: true,
                  employeeCode: true,
                  department: true,
                  branchId: true,
                  role: true,
                },
              },
            },
          },
          user: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
      });
      result = this.projectLeaveRequest(updated);

      await tx.auditLog.create({
        data: {
          actorUserId,
          action: isHr
            ? 'HR_CANCEL_LEAVE_REQUEST'
            : 'EMPLOYEE_CANCEL_LEAVE_REQUEST',
          targetType: 'LeaveRequest',
          targetId: id,
          metadata: { reason: data.reason },
        },
      });
    });

    // Post-commit notification
    this.events.emitToUser(ownerId, 'updated', result);
    return result;
  }

  async getTeamCalendar() {
    const requests = await this.prisma.leaveRequest.findMany({
      where: { overallStatus: 'approved' },
      select: {
        startDate: true,
        endDate: true,
        user: {
          select: {
            name: true,
          },
        },
      },
    });

    return requests.map((r) => ({
      colleagueName: r.user?.name ?? 'Employee',
      startDate: r.startDate,
      endDate: r.endDate,
    }));
  }

  // ==========================================
  // Approval Actions & Queues
  // ==========================================

  async getPendingApprovals(
    role: string,
    actorUserId: string,
    page: number = 1,
    limit: number = 10,
  ) {
    const safeLimit = Math.min(100, Math.max(1, limit));
    const skip = (Math.max(1, page) - 1) * safeLimit;

    // Map role to canonical backend step-name mapping
    const canonicalRole =
      role === 'teamLead' || role === 'team_lead'
        ? 'team_lead'
        : role === 'manager'
          ? 'manager'
          : 'hr';

    const targetStepOrder =
      canonicalRole === 'team_lead' ? 1 : canonicalRole === 'manager' ? 2 : 3; // HR steps

    const where: Prisma.LeaveRequestWhereInput = {
      overallStatus: 'pending',
      currentStepOrder: targetStepOrder,
      approvalSteps: {
        some: {
          stepOrder: targetStepOrder,
          expectedApproverId: actorUserId,
          status: 'pending',
          stepName: canonicalRole,
        },
      },
    };

    const [total, items] = await Promise.all([
      this.prisma.leaveRequest.count({ where }),
      this.prisma.leaveRequest.findMany({
        where,
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
              expectedApprover: {
                select: {
                  id: true,
                  name: true,
                  employeeCode: true,
                  department: true,
                  branchId: true,
                  role: true,
                },
              },
            },
          },
          user: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: safeLimit,
      }),
    ]);

    const projectedItems = items.map((item) => this.projectLeaveRequest(item));

    return {
      total,
      page,
      limit: safeLimit,
      totalPages: Math.ceil(total / safeLimit),
      items: projectedItems,
    };
  }

  async approveRequest(
    id: string,
    actorUserId: string,
    actorRole: string,
    data: ApprovalActionDto,
  ) {
    let result: any = null;
    let ownerId = '';
    let nextApproverId: string | null = null;
    let isFinal = false;
    let empToken: string | null = null;
    let empName = 'Employee';

    await this.runTransaction(async (tx) => {
      const req = await tx.leaveRequest.findUnique({
        where: { id },
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
            },
          },
        },
      });

      if (!req) throw new NotFoundException('Leave request not found');
      if (req.overallStatus !== 'pending') {
        throw new ForbiddenException('Request is not pending');
      }

      ownerId = req.userId;

      // Find the current pending step
      const pendingStep = req.approvalSteps.find(
        (s) => s.stepOrder === req.currentStepOrder,
      );
      if (!pendingStep || pendingStep.status !== 'pending') {
        throw new NotFoundException('Active step not found');
      }

      // Check authorization
      if (pendingStep.expectedApproverId !== actorUserId) {
        throw new ForbiddenException('NOT_EXPECTED_APPROVER');
      }

      // Verify role mapping
      if (pendingStep.stepName === 'team_lead' && actorRole !== 'team_lead') {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }
      if (pendingStep.stepName === 'manager' && actorRole !== 'manager') {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }
      if (
        pendingStep.stepName === 'hr' &&
        !['hr', 'hrAdmin', 'superAdmin'].includes(actorRole)
      ) {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }

      // Update approval step
      const now = this.companyTime.serverNowUtc();
      await tx.leaveApprovalStep.update({
        where: { id: pendingStep.id },
        data: { status: 'approved', timestamp: now },
      });

      // Fetch employee FCM details inside transaction safely
      const employee = await tx.user.findUnique({
        where: { id: req.userId },
        select: { fcmToken: true, name: true },
      });
      if (employee) {
        empToken = employee.fcmToken;
        empName = employee.name;
      }

      // Check if there is a next step
      const nextStep = req.approvalSteps.find(
        (s) => s.stepOrder > req.currentStepOrder,
      );

      if (nextStep) {
        // Advance to next step
        const updated = await tx.leaveRequest.update({
          where: { id },
          data: { currentStepOrder: nextStep.stepOrder },
          select: {
            id: true,
            userId: true,
            type: true,
            startDate: true,
            endDate: true,
            isHalfDay: true,
            halfDayPeriod: true,
            reason: true,
            hasAttachment: true,
            overallStatus: true,
            currentStepOrder: true,
            workingDays: true,
            createdAt: true,
            updatedAt: true,
            approvalSteps: {
              orderBy: { stepOrder: 'asc' },
              select: {
                id: true,
                requestId: true,
                stepName: true,
                status: true,
                stepOrder: true,
                timestamp: true,
                expectedApproverId: true,
                expectedApprover: {
                  select: {
                    id: true,
                    name: true,
                    employeeCode: true,
                    department: true,
                    branchId: true,
                    role: true,
                  },
                },
              },
            },
            user: {
              select: {
                id: true,
                name: true,
                employeeCode: true,
                department: true,
                branchId: true,
                role: true,
              },
            },
          },
        });
        result = this.projectLeaveRequest(updated);
        nextApproverId = nextStep.expectedApproverId;
      } else {
        // This is the final step
        isFinal = true;

        // Check policy
        const policy = await tx.leavePolicy.findUnique({
          where: { type: req.type },
        });
        const requiresBalance = policy ? policy.requiresBalance : true;

        if (requiresBalance) {
          const year = DateTime.fromJSDate(req.startDate).year;
          const balance = await tx.leaveBalance.findFirst({
            where: { userId: req.userId, type: req.type, year },
          });
          if (!balance) {
            throw new BadRequestException('LEAVE_BALANCE_NOT_FOUND');
          }

          const reserved = this.toDecimal(balance.reservedDays ?? 0);
          const used = this.toDecimal(balance.usedDays ?? 0);
          const workingDays = this.toDecimal(req.workingDays ?? 0);

          const newReserved = reserved.minus(workingDays);
          const newUsed = used.plus(workingDays);

          if (newReserved.lt(0) || newUsed.lt(0)) {
            throw new BadRequestException('INVALID_BALANCE_STATE');
          }

          await tx.leaveBalance.update({
            where: { id: balance.id },
            data: { reservedDays: newReserved, usedDays: newUsed },
          });
        }

        const updated = await tx.leaveRequest.update({
          where: { id },
          data: { overallStatus: 'approved' },
          select: {
            id: true,
            userId: true,
            type: true,
            startDate: true,
            endDate: true,
            isHalfDay: true,
            halfDayPeriod: true,
            reason: true,
            hasAttachment: true,
            overallStatus: true,
            currentStepOrder: true,
            workingDays: true,
            createdAt: true,
            updatedAt: true,
            approvalSteps: {
              orderBy: { stepOrder: 'asc' },
              select: {
                id: true,
                requestId: true,
                stepName: true,
                status: true,
                stepOrder: true,
                timestamp: true,
                expectedApproverId: true,
                expectedApprover: {
                  select: {
                    id: true,
                    name: true,
                    employeeCode: true,
                    department: true,
                    branchId: true,
                    role: true,
                  },
                },
              },
            },
            user: {
              select: {
                id: true,
                name: true,
                employeeCode: true,
                department: true,
                branchId: true,
                role: true,
              },
            },
          },
        });
        result = this.projectLeaveRequest(updated);
      }

      await tx.auditLog.create({
        data: {
          actorUserId,
          action: 'APPROVE_LEAVE_REQUEST',
          targetType: 'LeaveRequest',
          targetId: id,
          metadata: {
            stepName: pendingStep.stepName,
            isFinal,
            comment: data.comment,
          },
        },
      });
    });

    // Post-commit notifications
    this.events.emitToUser(ownerId, 'updated', result);

    if (empToken) {
      if (isFinal) {
        void this.notifications
          .notifyLeaveApproved(ownerId, empToken, empName, result.id)
          .catch(() => undefined);
      } else {
        void this.notifications
          .notifyLeaveStepApproved(ownerId, empToken, empName, result.id)
          .catch(() => undefined);
      }
    }

    if (nextApproverId) {
      this.events.emitToUser(nextApproverId, 'created', result);
      const nextApprover = await this.prisma.user.findUnique({
        where: { id: nextApproverId },
        select: { fcmToken: true },
      });
      if (nextApprover?.fcmToken) {
        void this.notifications
          .notifyNewLeaveRequest(nextApproverId, nextApprover.fcmToken, empName, result.id)
          .catch(() => undefined);
      }
    }

    return result;
  }

  async rejectRequest(
    id: string,
    actorUserId: string,
    actorRole: string,
    data: ApprovalActionDto,
  ) {
    if (!data.comment || data.comment.trim().length === 0) {
      throw new BadRequestException('REJECTION_REASON_REQUIRED');
    }

    let result: any = null;
    let ownerId = '';
    let empToken: string | null = null;
    let empName = 'Employee';

    await this.runTransaction(async (tx) => {
      const req = await tx.leaveRequest.findUnique({
        where: { id },
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
            },
          },
        },
      });

      if (!req) throw new NotFoundException('Leave request not found');
      if (req.overallStatus !== 'pending') {
        throw new ForbiddenException('Request is not pending');
      }

      ownerId = req.userId;

      // Find the current pending step
      const pendingStep = req.approvalSteps.find(
        (s) => s.stepOrder === req.currentStepOrder,
      );
      if (!pendingStep || pendingStep.status !== 'pending') {
        throw new NotFoundException('Active step not found');
      }

      // Check authorization
      if (pendingStep.expectedApproverId !== actorUserId) {
        throw new ForbiddenException('NOT_EXPECTED_APPROVER');
      }

      // Verify role mapping
      if (pendingStep.stepName === 'team_lead' && actorRole !== 'team_lead') {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }
      if (pendingStep.stepName === 'manager' && actorRole !== 'manager') {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }
      if (
        pendingStep.stepName === 'hr' &&
        !['hr', 'hrAdmin', 'superAdmin'].includes(actorRole)
      ) {
        throw new ForbiddenException('INVALID_APPROVER_ROLE');
      }

      // Update approval step
      const now = this.companyTime.serverNowUtc();
      await tx.leaveApprovalStep.update({
        where: { id: pendingStep.id },
        data: { status: 'rejected', timestamp: now },
      });

      // Release reserved days
      const policy = await tx.leavePolicy.findUnique({
        where: { type: req.type },
      });
      const requiresBalance = policy ? policy.requiresBalance : true;

      if (requiresBalance) {
        const year = DateTime.fromJSDate(req.startDate).year;
        const balance = await tx.leaveBalance.findFirst({
          where: { userId: req.userId, type: req.type, year },
        });
        if (balance) {
          const reserved = this.toDecimal(balance.reservedDays ?? 0);
          const workingDays = this.toDecimal(req.workingDays ?? 0);
          const newReserved = reserved.minus(workingDays);
          if (newReserved.lt(0)) {
            throw new BadRequestException('INVALID_BALANCE_STATE');
          }

          await tx.leaveBalance.update({
            where: { id: balance.id },
            data: { reservedDays: newReserved },
          });
        }
      }

      // Fetch employee FCM details inside transaction safely
      const employee = await tx.user.findUnique({
        where: { id: req.userId },
        select: { fcmToken: true, name: true },
      });
      if (employee) {
        empToken = employee.fcmToken;
        empName = employee.name;
      }

      const updated = await tx.leaveRequest.update({
        where: { id },
        data: { overallStatus: 'rejected' },
        select: {
          id: true,
          userId: true,
          type: true,
          startDate: true,
          endDate: true,
          isHalfDay: true,
          halfDayPeriod: true,
          reason: true,
          hasAttachment: true,
          overallStatus: true,
          currentStepOrder: true,
          workingDays: true,
          createdAt: true,
          updatedAt: true,
          approvalSteps: {
            orderBy: { stepOrder: 'asc' },
            select: {
              id: true,
              requestId: true,
              stepName: true,
              status: true,
              stepOrder: true,
              timestamp: true,
              expectedApproverId: true,
              expectedApprover: {
                select: {
                  id: true,
                  name: true,
                  employeeCode: true,
                  department: true,
                  branchId: true,
                  role: true,
                },
              },
            },
          },
          user: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              department: true,
              branchId: true,
              role: true,
            },
          },
        },
      });
      result = this.projectLeaveRequest(updated);

      await tx.auditLog.create({
        data: {
          actorUserId,
          action: 'REJECT_LEAVE_REQUEST',
          targetType: 'LeaveRequest',
          targetId: id,
          metadata: { stepName: pendingStep.stepName, comment: data.comment },
        },
      });
    });

    // Post-commit notifications
    this.events.emitToUser(ownerId, 'updated', result);

    if (empToken) {
      void this.notifications
        .notifyLeaveRejected(ownerId, empToken, empName, result.id)
        .catch(() => undefined);
    }

    return result;
  }
}
