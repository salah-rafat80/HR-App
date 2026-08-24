/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any, @typescript-eslint/unbound-method */
import { Test, TestingModule } from '@nestjs/testing';
import { AppraisalService } from './appraisal.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { CompanyTimeService } from '../common/time/company-time.service';
import {
  ForbiddenException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';

describe('AppraisalService', () => {
  let service: AppraisalService;

  const mockPrisma = {
    appraisalCycle: {
      findFirst: jest.fn(),
      updateMany: jest.fn(),
      create: jest.fn(),
    },
    selfAppraisalAnswer: {
      count: jest.fn(),
      upsert: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    peerFeedback: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    $transaction: jest.fn(async (cb) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppraisalService,
        CompanyTimeService,
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
        {
          provide: EventsGateway,
          useValue: {
            emitEntityUpdated: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AppraisalService>(AppraisalService);
    jest.clearAllMocks();
  });

  describe('startNewCycle', () => {
    it('should throw ForbiddenException if user is not HR/Admin', async () => {
      await expect(
        service.startNewCycle('user-1', 'employee', 'Q3 2026', new Date()),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.startNewCycle('user-1', 'manager', 'Q3 2026', new Date()),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow hrAdmin to start a new cycle', async () => {
      mockPrisma.appraisalCycle.create.mockResolvedValue({
        label: 'Q3 2026',
        status: 'inProgress',
        dueDate: new Date(),
      });

      const result = await service.startNewCycle(
        'user-hr',
        'hrAdmin',
        'Q3 2026',
        new Date(),
      );
      expect(result.status).toBe('inProgress');
      expect(mockPrisma.appraisalCycle.updateMany).toHaveBeenCalled();
    });

    it('should allow superAdmin to start a new cycle', async () => {
      mockPrisma.appraisalCycle.create.mockResolvedValue({
        label: 'Q3 2026',
        status: 'inProgress',
        dueDate: new Date(),
      });

      const result = await service.startNewCycle(
        'user-sa',
        'superAdmin',
        'Q3 2026',
        new Date(),
      );
      expect(result.status).toBe('inProgress');
    });
  });

  describe('getPeersForFeedback', () => {
    it('should throw NotFoundException if current user is not found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      await expect(service.getPeersForFeedback('unknown')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should query peers restricted by department and branch', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        department: 'IT',
        branchId: 'branch-1',
      });
      mockPrisma.user.findMany.mockResolvedValue([]);
      mockPrisma.appraisalCycle.findFirst.mockResolvedValue(null);

      await service.getPeersForFeedback('user-1');
      expect(mockPrisma.user.findMany).toHaveBeenCalledWith({
        where: {
          id: { not: 'user-1' },
          isActive: true,
          department: 'IT',
          branchId: 'branch-1',
        },
        take: 20,
      });
    });

    it('should return only peers from the same branch and department (behavioral)', async () => {
      // Mock the current user
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user-req',
        department: 'IT',
        branchId: 'branch-A',
      });

      // We implement a mock findMany that actually filters a mock database array
      // Note: There is no 'companyId' in the schema, so company isolation is implicitly
      // single-tenant. The highest isolation is branch/department.
      const allMockUsers = [
        {
          id: 'user-req',
          name: 'Req',
          role: 'employee',
          department: 'IT',
          branchId: 'branch-A',
        },
        {
          id: 'user-diff-branch',
          name: 'Diff Branch',
          role: 'employee',
          department: 'IT',
          branchId: 'branch-B',
        },
        {
          id: 'user-diff-dept',
          name: 'Diff Dept',
          role: 'employee',
          department: 'HR',
          branchId: 'branch-A',
        },
        {
          id: 'user-valid',
          name: 'Valid Peer',
          role: 'employee',
          department: 'IT',
          branchId: 'branch-A',
        },
      ];

      mockPrisma.user.findMany.mockImplementation(async (args) => {
        const { where } = args;
        return allMockUsers.filter(
          (u) =>
            u.id !== where.id.not &&
            u.department === where.department &&
            u.branchId === where.branchId,
        );
      });

      mockPrisma.appraisalCycle.findFirst.mockResolvedValue(null);

      const result = await service.getPeersForFeedback('user-req');

      // Assert that only the valid user is returned in the final mapped list
      expect(result.length).toBe(1);
      expect(result[0].colleague.id).toBe('user-valid');

      // Ensure the requesting user, different branch, and different department users are excluded
      const ids = result.map((r) => r.colleague.id);
      expect(ids).not.toContain('user-req');
      expect(ids).not.toContain('user-diff-branch');
      expect(ids).not.toContain('user-diff-dept');
    });
  });

  describe('submitSelfAppraisal', () => {
    it('should throw NotFoundException if no active cycle', async () => {
      mockPrisma.appraisalCycle.findFirst.mockResolvedValue(null);
      await expect(service.submitSelfAppraisal('user-1', [])).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException if invalid question ID is submitted', async () => {
      mockPrisma.appraisalCycle.findFirst.mockResolvedValue({ id: 'cycle-1' });
      await expect(
        service.submitSelfAppraisal('user-1', [
          { id: 'invalid-id', questionText: '?', answerText: 'A' },
        ]),
      ).rejects.toThrow(BadRequestException);
    });

    it('should use transaction to save answers and emit update', async () => {
      mockPrisma.appraisalCycle.findFirst.mockResolvedValue({
        id: 'cycle-1',
        status: 'inProgress',
      });
      mockPrisma.selfAppraisalAnswer.count.mockResolvedValue(1);

      await service.submitSelfAppraisal('user-1', [
        { id: 'q1', questionText: 'Q1', answerText: 'A1' },
      ]);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockPrisma.selfAppraisalAnswer.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            userId_cycleId_questionId: {
              userId: 'user-1',
              cycleId: 'cycle-1',
              questionId: 'q1',
            },
          },
        }),
      );
    });

    it('should rollback transaction if an upsert fails', async () => {
      mockPrisma.appraisalCycle.findFirst.mockResolvedValue({
        id: 'cycle-1',
        status: 'inProgress',
      });

      // Create a mock transaction client
      const mockTx = {
        selfAppraisalAnswer: {
          upsert: jest.fn().mockImplementation((args) => {
            if (args.where.userId_cycleId_questionId.questionId === 'q2') {
              throw new Error('Database Failure on q2');
            }
            return Promise.resolve({ id: 'success' });
          }),
        },
      };

      // Mock $transaction to execute the callback with the mockTx
      mockPrisma.$transaction.mockImplementationOnce(async (cb) => {
        return await cb(mockTx);
      });

      const answers = [
        { id: 'q1', questionText: 'Q1', answerText: 'A1' }, // Should succeed
        { id: 'q2', questionText: 'Q2', answerText: 'A2' }, // Should throw
      ];

      await expect(
        service.submitSelfAppraisal('user-1', answers),
      ).rejects.toThrow('Database Failure on q2');

      // The transaction function is atomic, so if the promise rejects, Prisma rolls it back.
      // Assert that the service did NOT return success.
      expect(mockTx.selfAppraisalAnswer.upsert).toHaveBeenCalledTimes(2);
      expect(mockPrisma.appraisalCycle.findFirst).toHaveBeenCalledTimes(1); // the initial check
    });
  });
});
