import { Test, TestingModule } from '@nestjs/testing';
import { KpiService } from './kpi.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

type MockFn = jest.Mock;

interface MockPrisma {
  kpi: {
    findMany: MockFn;
    findUnique: MockFn;
    update: MockFn;
    create: MockFn;
  };
  kpiQuarterScore: {
    findMany: MockFn;
  };
  user: {
    findMany: MockFn;
    findUnique: MockFn;
  };
  leaveRequest: {
    findMany: MockFn;
  };
  attendanceRecord: {
    findMany: MockFn;
  };
}

describe('KpiService', () => {
  let service: KpiService;
  let prismaMock: MockPrisma;
  let eventsMock: { emitEntityUpdated: MockFn };

  beforeEach(async () => {
    prismaMock = {
      kpi: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        create: jest.fn(),
      },
      kpiQuarterScore: {
        findMany: jest.fn(),
      },
      user: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
      },
      leaveRequest: {
        findMany: jest.fn(),
      },
      attendanceRecord: {
        findMany: jest.fn(),
      },
    };

    eventsMock = {
      emitEntityUpdated: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        KpiService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: EventsGateway, useValue: eventsMock },
      ],
    }).compile();

    service = module.get<KpiService>(KpiService);
  });

  describe('getCurrentKpis', () => {
    it('scopes query to authenticated userId and returns array', async () => {
      prismaMock.kpi.findMany.mockResolvedValue([
        {
          id: 'kpi1',
          userId: 'user-123',
          title: 'Sales Goal',
          targetValue: 100,
          currentValue: 80,
        },
      ]);

      const res = await service.getCurrentKpis('user-123');
      expect(prismaMock.kpi.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        orderBy: { createdAt: 'desc' },
        select: expect.any(Object),
      });
      expect(res).toHaveLength(1);
    });

    it('returns empty array when database has no KPIs', async () => {
      prismaMock.kpi.findMany.mockResolvedValue([]);
      const res = await service.getCurrentKpis('user-empty');
      expect(res).toEqual([]);
    });
  });

  describe('getHistoricalScores', () => {
    it('scopes query to authenticated userId', async () => {
      prismaMock.kpiQuarterScore.findMany.mockResolvedValue([]);
      const res = await service.getHistoricalScores('user-123');
      expect(prismaMock.kpiQuarterScore.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        orderBy: { quarterLabel: 'desc' },
        select: expect.any(Object),
      });
      expect(res).toEqual([]);
    });
  });

  describe('getOverallQuarterScore', () => {
    it('returns { overallScore: 0.0 } when no KPIs exist', async () => {
      prismaMock.kpi.findMany.mockResolvedValue([]);
      const res = await service.getOverallQuarterScore('user-123');
      expect(res).toEqual({ overallScore: 0.0 });
    });

    it('calculates average score correctly', async () => {
      prismaMock.kpi.findMany.mockResolvedValue([
        { targetValue: 100, currentValue: 50 },
        { targetValue: 100, currentValue: 100 },
      ]);
      const res = await service.getOverallQuarterScore('user-123');
      expect(res).toEqual({ overallScore: 0.75 });
    });
  });

  describe('getTeamKpis', () => {
    it('returns empty array when manager has no managed employees (zero N+1 queries)', async () => {
      prismaMock.user.findMany.mockResolvedValue([]);
      const res = await service.getTeamKpis('mgr-123', 'manager');
      expect(res).toEqual([]);
      expect(prismaMock.leaveRequest.findMany).not.toHaveBeenCalled();
      expect(prismaMock.attendanceRecord.findMany).not.toHaveBeenCalled();
    });

    it('bulk fetches team data in batch queries without per-member N+1 loop', async () => {
      prismaMock.user.findMany
        .mockResolvedValueOnce([{ id: 'emp-1' }, { id: 'emp-2' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([
          {
            id: 'emp-1',
            name: 'Emp One',
            title: 'Dev',
            department: 'IT',
            kpis: [{ targetValue: 100, currentValue: 90 }],
          },
          {
            id: 'emp-2',
            name: 'Emp Two',
            title: 'QA',
            department: 'IT',
            kpis: [],
          },
        ]);

      prismaMock.leaveRequest.findMany.mockResolvedValue([{ userId: 'emp-1' }]);
      prismaMock.attendanceRecord.findMany.mockResolvedValue([
        { userId: 'emp-2' },
      ]);

      const res = await service.getTeamKpis('mgr-123', 'manager');

      expect(res).toHaveLength(2);
      expect(res[0]).toEqual({
        id: 'emp-1',
        name: 'Emp One',
        title: 'Dev',
        department: 'IT',
        kpiScorePercent: 0.9,
        leaveStatus: 'onLeave',
      });
      expect(res[1]).toEqual({
        id: 'emp-2',
        name: 'Emp Two',
        title: 'QA',
        department: 'IT',
        kpiScorePercent: 0,
        leaveStatus: 'wfh',
      });

      expect(prismaMock.leaveRequest.findMany).toHaveBeenCalledWith({
        where: {
          userId: { in: ['emp-1', 'emp-2'] },
          overallStatus: 'approved',
          startDate: { lte: expect.any(Date) },
          endDate: { gte: expect.any(Date) },
        },
        select: { userId: true },
      });
      expect(prismaMock.attendanceRecord.findMany).toHaveBeenCalledWith({
        where: {
          userId: { in: ['emp-1', 'emp-2'] },
          date: { gte: expect.any(Date), lte: expect.any(Date) },
          status: 'workFromHome',
        },
        select: { userId: true },
      });
    });
  });

  describe('submitSelfAssessment & attachEvidence', () => {
    it('throws ForbiddenException when editing KPI belonging to another user', async () => {
      prismaMock.kpi.findUnique.mockResolvedValue({
        id: 'kpi-1',
        userId: 'user-other',
      });

      await expect(
        service.submitSelfAssessment('user-me', 'kpi-1', 'assessment text'),
      ).rejects.toThrow(ForbiddenException);

      await expect(service.attachEvidence('user-me', 'kpi-1')).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('throws NotFoundException when KPI does not exist', async () => {
      prismaMock.kpi.findUnique.mockResolvedValue(null);

      await expect(
        service.submitSelfAssessment('user-me', 'non-existent', 'text'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('assignKpi', () => {
    it('forbids assigning KPI to employee outside reporting chain for non-HR manager', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: 'target-1',
        managerId: 'other-mgr',
      });
      prismaMock.user.findMany.mockResolvedValue([]);

      await expect(
        service.assignKpi('mgr-1', 'manager', {
          memberId: 'target-1',
          title: 'New KPI',
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
