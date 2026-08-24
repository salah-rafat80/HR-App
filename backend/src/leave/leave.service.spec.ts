/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any, @typescript-eslint/unbound-method */
import { Test, TestingModule } from '@nestjs/testing';
import { LeaveService } from './leave.service';
import { LeaveCalendarService } from './leave-calendar.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';
import { CompanyTimeService } from '../common/time/company-time.service';
import { Prisma, LeaveType } from '@prisma/client';
import { DateTime } from 'luxon';

describe('LeaveService', () => {
  let service: LeaveService;
  let calendar: LeaveCalendarService;
  let companyTime: CompanyTimeService;

  const mockPrisma = {
    leavePolicy: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    leaveBalance: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    leaveRequest: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    leaveApprovalStep: {
      update: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    companyLeaveApprovalConfiguration: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      upsert: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    companyHoliday: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
    },
    attendanceRecord: {
      findFirst: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeaveService,
        CompanyTimeService,
        {
          provide: LeaveCalendarService,
          useValue: {
            calculateWorkingDays: jest.fn(),
          },
        },
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
        {
          provide: EventsGateway,
          useValue: {
            emitToUser: jest.fn(),
            emitToRole: jest.fn(),
            emitEntityUpdated: jest.fn(),
          },
        },
        {
          provide: NotificationService,
          useValue: {
            notifyNewLeaveRequest: jest.fn(),
            notifyLeaveApproved: jest.fn(),
            notifyLeaveRejected: jest.fn(),
            sendToDevice: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<LeaveService>(LeaveService);
    companyTime = module.get<CompanyTimeService>(CompanyTimeService);
    calendar = module.get<LeaveCalendarService>(LeaveCalendarService);

    // Clear mock histories
    jest.clearAllMocks();
  });

  describe('Approval Chain & Config Validation', () => {
    it('should throw MISSING_FINAL_HR_APPROVER if final HR configuration is missing', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        null,
      );

      await expect(
        service.applyLeave('user-1', {
          type: LeaveType.annual,
          startDate: '2026-08-20',
          endDate: '2026-08-21',
          isHalfDay: false,
          reason: 'Vacation',
        }),
      ).rejects.toThrow('MISSING_FINAL_HR_APPROVER');
    });

    it('should throw MISSING_TEAM_LEAD_APPROVER if employee has no assigned Team Lead', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        { finalHrApproverId: 'hr-approver-id' },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        role: 'employee',
        manager: null,
      });

      await expect(
        service.applyLeave('user-1', {
          type: LeaveType.annual,
          startDate: '2026-08-20',
          endDate: '2026-08-21',
          isHalfDay: false,
          reason: 'Vacation',
        }),
      ).rejects.toThrow('MISSING_TEAM_LEAD_APPROVER');
    });

    it('should throw MISSING_MANAGER_APPROVER if employee Team Lead has no assigned Manager', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        { finalHrApproverId: 'hr-approver-id' },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        role: 'employee',
        manager: {
          id: 'tl-1',
          role: 'team_lead',
          manager: null,
        },
      });

      await expect(
        service.applyLeave('user-1', {
          type: LeaveType.annual,
          startDate: '2026-08-20',
          endDate: '2026-08-21',
          isHalfDay: false,
          reason: 'Vacation',
        }),
      ).rejects.toThrow('MISSING_MANAGER_APPROVER');
    });

    it('should throw MISSING_TEAM_LEAD_APPROVER if employee Team Lead belongs to a different department', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        { finalHrApproverId: 'hr-approver-id' },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        role: 'employee',
        department: 'Engineering',
        manager: {
          id: 'tl-1',
          role: 'team_lead',
          department: 'Sales',
          manager: {
            id: 'mgr-1',
            role: 'manager',
            department: 'Engineering',
          },
        },
      });

      await expect(
        service.applyLeave('user-1', {
          type: LeaveType.annual,
          startDate: '2026-08-20',
          endDate: '2026-08-21',
          isHalfDay: false,
          reason: 'Vacation',
        }),
      ).rejects.toThrow('MISSING_TEAM_LEAD_APPROVER');
    });

    it('should reject submission from HR, hrAdmin, or superAdmin to prevent self-approval', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        {
          finalHrApproverId: 'hr-approver-id',
        },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'hr-user-id',
        role: 'hr',
      });

      await expect(
        service.applyLeave('hr-user-id', {
          type: LeaveType.annual,
          startDate: '2026-08-20',
          endDate: '2026-08-21',
          isHalfDay: false,
          reason: 'Vacation',
        }),
      ).rejects.toThrow('LEAVE_APPROVAL_CHAIN_NOT_CONFIGURED');
    });

    it('should configure 3 steps for employee (TL -> Manager -> HR)', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        {
          finalHrApproverId: 'hr-approver-id',
        },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'employee-id',
        role: 'employee',
        managerId: 'tl-id',
        manager: {
          id: 'tl-id',
          role: 'team_lead',
          managerId: 'mgr-id',
          manager: {
            id: 'mgr-id',
            role: 'manager',
          },
        },
      });

      mockPrisma.leavePolicy.findUnique.mockResolvedValue({
        isActive: true,
        requiresBalance: false,
        minimumNoticeDays: 0,
        requiresReason: true,
      });

      jest
        .spyOn(calendar, 'calculateWorkingDays')
        .mockResolvedValue(new Prisma.Decimal('2'));
      mockPrisma.leaveRequest.findFirst.mockResolvedValue(null); // No overlap
      mockPrisma.companyHoliday.findFirst.mockResolvedValue(null);

      mockPrisma.leaveRequest.create.mockImplementation((args) => {
        const approvalSteps = args.data.approvalSteps.create.map(
          (step, idx) => ({
            id: `step-${idx}`,
            requestId: 'req-1',
            ...step,
          }),
        );
        return {
          id: 'req-1',
          ...args.data,
          approvalSteps,
        };
      });

      const today = companyTime.companyBusinessDate();
      const tomorrow = DateTime.fromISO(today).plus({ days: 1 }).toISODate()!;

      const req = await service.applyLeave('employee-id', {
        type: LeaveType.annual,
        startDate: today,
        endDate: tomorrow,
        isHalfDay: false,
        reason: 'Vacation',
      });

      expect(req.approvalSteps).toHaveLength(3);
      expect(req.approvalSteps[0].stepName).toBe('team_lead');
      expect(req.approvalSteps[0].expectedApproverId).toBe('tl-id');
      expect(req.approvalSteps[1].stepName).toBe('manager');
      expect(req.approvalSteps[1].expectedApproverId).toBe('mgr-id');
      expect(req.approvalSteps[2].stepName).toBe('hr');
      expect(req.approvalSteps[2].expectedApproverId).toBe('hr-approver-id');
    });
  });

  describe('expectedApprover Authorization & Rejection of SuperAdmin Bypass', () => {
    it('should reject approval if actor is not the expectedApprover for the current step', async () => {
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        userId: 'employee-id',
        overallStatus: 'pending',
        currentStepOrder: 1,
        workingDays: new Prisma.Decimal('2'),
        approvalSteps: [
          {
            id: 'step-1',
            stepOrder: 1,
            stepName: 'team_lead',
            status: 'pending',
            expectedApproverId: 'tl-id',
          },
          {
            id: 'step-2',
            stepOrder: 2,
            stepName: 'manager',
            status: 'pending',
            expectedApproverId: 'mgr-id',
          },
        ],
      });

      await expect(
        service.approveRequest(
          'req-1',
          'unauthorized-user-id',
          'team_lead',
          {},
        ),
      ).rejects.toThrow('NOT_EXPECTED_APPROVER');
    });

    it('should reject superAdmin trying to bypass TL or Manager steps', async () => {
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        userId: 'employee-id',
        overallStatus: 'pending',
        currentStepOrder: 1,
        workingDays: new Prisma.Decimal('2'),
        approvalSteps: [
          {
            id: 'step-1',
            stepOrder: 1,
            stepName: 'team_lead',
            status: 'pending',
            expectedApproverId: 'tl-id',
          },
        ],
      });

      await expect(
        service.approveRequest('req-1', 'super-admin-id', 'superAdmin', {}),
      ).rejects.toThrow('NOT_EXPECTED_APPROVER'); // Must be expected approver
    });

    it('should reject HR step approval before request reaches HR step order', async () => {
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        userId: 'employee-id',
        overallStatus: 'pending',
        currentStepOrder: 1, // Currently at TL step
        workingDays: new Prisma.Decimal('2'),
        approvalSteps: [
          {
            id: 'step-1',
            stepOrder: 1,
            stepName: 'team_lead',
            status: 'pending',
            expectedApproverId: 'tl-id',
          },
          {
            id: 'step-2',
            stepOrder: 2,
            stepName: 'manager',
            status: 'pending',
            expectedApproverId: 'mgr-id',
          },
          {
            id: 'step-3',
            stepOrder: 3,
            stepName: 'hr',
            status: 'pending',
            expectedApproverId: 'hr-id',
          },
        ],
      });

      // HR actor tries to approve step 3 (active order is 1)
      await expect(
        service.approveRequest('req-1', 'hr-id', 'hr', {}),
      ).rejects.toThrow('NOT_EXPECTED_APPROVER'); // Not expected for currentStepOrder (1)
    });
  });

  describe('Decimal Precision & Operations', () => {
    it('should preserve Decimal values without js number conversion', async () => {
      mockPrisma.leaveBalance.findFirst.mockResolvedValue({
        id: 'balance-1',
        entitledDays: new Prisma.Decimal('30.00'),
        adjustmentDays: new Prisma.Decimal('0.50'),
        reservedDays: new Prisma.Decimal('1.25'),
        usedDays: new Prisma.Decimal('0.00'),
      });

      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        {
          finalHrApproverId: 'hr-id',
        },
      );
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'employee-id',
        role: 'manager', // manager -> HR only
      });
      mockPrisma.leavePolicy.findUnique.mockResolvedValue({
        isActive: true,
        requiresBalance: true,
        minimumNoticeDays: 0,
        requiresReason: true,
      });

      jest
        .spyOn(calendar, 'calculateWorkingDays')
        .mockResolvedValue(new Prisma.Decimal('1.50'));
      mockPrisma.leaveRequest.findFirst.mockResolvedValue(null);
      mockPrisma.companyHoliday.findFirst.mockResolvedValue(null);

      mockPrisma.leaveRequest.create.mockImplementation((args) => ({
        id: 'req-1',
        ...args.data,
      }));

      const today = companyTime.companyBusinessDate();
      const tomorrow = DateTime.fromISO(today).plus({ days: 1 }).toISODate()!;

      await service.applyLeave('employee-id', {
        type: LeaveType.annual,
        startDate: today,
        endDate: tomorrow,
        isHalfDay: false,
        reason: 'Vacation',
      });

      // Verify entitled (30) + adjustment (0.5) - reserved (1.25) can fit 1.50
      // 30.5 - 1.25 = 29.25 >= 1.50 -> Success
      expect(mockPrisma.leaveBalance.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            reservedDays: new Prisma.Decimal('2.75'), // 1.25 + 1.50
          },
        }),
      );
    });
  });

  describe('Idempotency & One-time Transitions', () => {
    it('should reject approving an already approved request', async () => {
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        overallStatus: 'approved', // already approved
      });

      await expect(
        service.approveRequest('req-1', 'hr-id', 'hr', {}),
      ).rejects.toThrow('Request is not pending');
    });

    it('should reject rejecting an already cancelled request', async () => {
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        overallStatus: 'cancelled', // already cancelled
      });

      await expect(
        service.rejectRequest('req-1', 'hr-id', 'hr', { comment: 'Rejected' }),
      ).rejects.toThrow('Request is not pending');
    });
  });

  describe('Required Security & Compatibility Checks', () => {
    it('GET config causes no create', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        null,
      );
      const res = await service.getCompanyApprovalConfig();
      expect(res).toEqual({
        configured: false,
        id: null,
        finalHrApproverId: null,
        finalHrApprover: null,
      });
      expect(
        mockPrisma.companyLeaveApprovalConfiguration.create,
      ).not.toHaveBeenCalled();
    });

    it('safe selections do not expose passwordHash/fcmToken', () => {
      const mockUser = {
        id: 'user-1',
        name: 'Ahmed',
        passwordHash: 'secret_hash',
        fcmToken: 'fcm_token_123',
        role: 'employee',
      };

      const reqWithSecrets = {
        id: 'req-1',
        userId: 'user-1',
        user: mockUser,
        approvalSteps: [
          {
            id: 'step-1',
            expectedApprover: mockUser,
          },
        ],
      };

      const res = (service as any).projectLeaveRequest(reqWithSecrets);
      expect(res.user.passwordHash).toBeUndefined();
      expect(res.user.fcmToken).toBeUndefined();
      expect(
        res.approvalSteps[0].expectedApprover.passwordHash,
      ).toBeUndefined();
      expect(res.approvalSteps[0].expectedApprover.fcmToken).toBeUndefined();
    });

    it('paginated exact-approver queue matches correct step and role', async () => {
      mockPrisma.leaveRequest.count.mockResolvedValue(1);
      mockPrisma.leaveRequest.findMany.mockResolvedValue([
        {
          id: 'req-1',
          userId: 'emp-1',
          overallStatus: 'pending',
          currentStepOrder: 1,
          approvalSteps: [
            {
              id: 'step-1',
              stepOrder: 1,
              expectedApproverId: 'approver-1',
              status: 'pending',
              stepName: 'team_lead',
            },
          ],
          user: {
            id: 'emp-1',
            name: 'Ahmed',
          },
        },
      ]);

      const res = await service.getPendingApprovals(
        'team_lead',
        'approver-1',
        1,
        10,
      );
      expect(res.total).toBe(1);
      expect(res.items[0].id).toBe('req-1');
      expect(mockPrisma.leaveRequest.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            overallStatus: 'pending',
            currentStepOrder: 1,
            approvalSteps: {
              some: expect.objectContaining({
                stepOrder: 1,
                expectedApproverId: 'approver-1',
                status: 'pending',
                stepName: 'team_lead',
              }),
            },
          }),
        }),
      );
    });

    it('Employee policy list does not return inactive policy; admin list does', async () => {
      mockPrisma.leavePolicy.findMany.mockImplementation((args) => {
        const inactiveFiltered = args && args.where && args.where.isActive;
        if (inactiveFiltered) {
          return Promise.resolve([{ type: 'annual', isActive: true }]);
        }
        return Promise.resolve([
          { type: 'annual', isActive: true },
          { type: 'sick', isActive: false },
        ]);
      });

      const employeePolicies = await service.getPolicies(false);
      expect(employeePolicies).toHaveLength(1);
      expect(employeePolicies[0].isActive).toBe(true);

      const adminPolicies = await service.getPolicies(true);
      expect(adminPolicies).toHaveLength(2);
    });

    it('Concurrent configuration writes cannot create more than one configuration record via upsert', async () => {
      mockPrisma.companyLeaveApprovalConfiguration.upsert.mockImplementation(
        (args) => {
          expect(args.where.id).toBe('default');
          expect(args.create.id).toBe('default');
          return Promise.resolve({
            id: 'default',
            finalHrApproverId: args.update.finalHrApproverId,
          });
        },
      );

      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        {
          id: 'default',
          finalHrApproverId: 'hr-1',
        },
      );

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'hr-1',
        role: 'hr',
        isActive: true,
      });

      const res = await service.updateCompanyApprovalConfig('admin-1', 'hr-1');
      expect(res.id).toBe('default');
      expect(res.finalHrApproverId).toBe('hr-1');
      expect(
        mockPrisma.companyLeaveApprovalConfiguration.upsert,
      ).toHaveBeenCalled();
    });

    it('SuperAdmin cannot approve TL/Manager step unless exact expected approver AND the current step is HR', async () => {
      // 1. Current step is TL, actor is superAdmin (not TL expected approver) -> should throw
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        userId: 'emp-1',
        overallStatus: 'pending',
        currentStepOrder: 1,
        approvalSteps: [
          {
            id: 'step-1',
            stepOrder: 1,
            stepName: 'team_lead',
            status: 'pending',
            expectedApproverId: 'tl-1',
          },
        ],
      });

      await expect(
        service.approveRequest('req-1', 'super-admin-id', 'superAdmin', {
          comment: 'ok',
        }),
      ).rejects.toThrow('NOT_EXPECTED_APPROVER');

      // 2. Current step is HR, actor is superAdmin and is configured as the expected approver -> succeeds
      mockPrisma.leaveRequest.findUnique.mockResolvedValue({
        id: 'req-1',
        userId: 'emp-1',
        overallStatus: 'pending',
        currentStepOrder: 3,
        approvalSteps: [
          {
            id: 'step-3',
            stepOrder: 3,
            stepName: 'hr',
            status: 'pending',
            expectedApproverId: 'super-admin-id',
          },
        ],
      });

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'emp-1',
        name: 'Employee',
      });

      mockPrisma.leaveRequest.update.mockResolvedValue({
        id: 'req-1',
        userId: 'emp-1',
        overallStatus: 'approved',
      });

      const res = await service.approveRequest(
        'req-1',
        'super-admin-id',
        'superAdmin',
        { comment: 'ok' },
      );
      expect(res.overallStatus).toBe('approved');
    });

    it('SuperAdmin can read/administer Leave config and policies/balances as intended', async () => {
      // Config GET
      mockPrisma.companyLeaveApprovalConfiguration.findUnique.mockResolvedValue(
        {
          id: 'default',
          finalHrApproverId: 'hr-1',
        },
      );
      const config = await service.getCompanyApprovalConfig();
      expect(config.configured).toBe(true);

      // Balances admin read
      mockPrisma.leaveBalance.count.mockResolvedValue(1);
      mockPrisma.leaveBalance.findMany.mockResolvedValue([
        { id: 'bal-1', userId: 'user-1' },
      ]);
      const balances = await service.getBalancesAdmin(1, 10);
      expect(balances.total).toBe(1);
    });

    it('should return minimal safe fields for employee picker without exposing sensitive fields', async () => {
      mockPrisma.user.findMany.mockResolvedValue([
        {
          id: 'user-1',
          name: 'Jane Doe',
          employeeCode: 'EMP001',
          department: 'Engineering',
          branchId: 'branch-1',
          role: 'employee',
        },
      ]);

      const employees = await service.getEmployeesForPicker();
      expect(mockPrisma.user.findMany).toHaveBeenCalledWith({
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
      expect(employees).toHaveLength(1);
      expect(employees[0]).not.toHaveProperty('password');
      expect(employees[0]).not.toHaveProperty('fcmToken');
    });
  });
});
