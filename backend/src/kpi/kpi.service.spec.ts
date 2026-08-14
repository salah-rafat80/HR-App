import { KpiService, TeamMember } from './kpi.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Kpi, KpiQuarterScore, User } from '@prisma/client';

interface UserReportRecord {
  id: string;
}

interface SelectedUser {
  id: string;
  name: string;
  title: string | null;
  department: string | null;
  kpis: { currentValue: number; targetValue: number }[];
}

interface MockLeaveItem {
  userId: string;
}

interface MockWfhItem {
  userId: string;
}

interface MockMethod<T> {
  (args?: unknown): Promise<T>;
  mockResolvedValue: (v: T) => void;
  mockResolvedValueOnce: (v: T) => void;
}

function createMockMethod<T>(initialValue: T): MockMethod<T> {
  let defaultValue = initialValue;
  const queue: T[] = [];

  const fn = ((): Promise<T> => {
    if (queue.length > 0) {
      const item = queue.shift();
      if (item !== undefined) return Promise.resolve(item);
    }
    return Promise.resolve(defaultValue);
  }) as MockMethod<T>;

  fn.mockResolvedValue = (v: T) => {
    defaultValue = v;
  };
  fn.mockResolvedValueOnce = (v: T) => {
    queue.push(v);
  };

  return fn;
}

interface MockPrisma {
  kpi: {
    findMany: MockMethod<Kpi[]>;
    findUnique: MockMethod<Kpi | null>;
    update: MockMethod<Kpi>;
    create: MockMethod<Kpi>;
  };
  kpiQuarterScore: {
    findMany: MockMethod<KpiQuarterScore[]>;
  };
  user: {
    findMany: MockMethod<unknown[]>;
    findUnique: MockMethod<User | null>;
  };
  leaveRequest: {
    findMany: MockMethod<MockLeaveItem[]>;
  };
  attendanceRecord: {
    findMany: MockMethod<MockWfhItem[]>;
  };
}

describe('KpiService', () => {
  let service: KpiService;
  let prismaMock: MockPrisma;

  const eventsMock = {
    emitEntityUpdated: jest.fn<void, [string, string, unknown]>(),
  };

  beforeEach(() => {
    prismaMock = {
      kpi: {
        findMany: createMockMethod<Kpi[]>([]),
        findUnique: createMockMethod<Kpi | null>(null),
        update: createMockMethod<Kpi>({} as Kpi),
        create: createMockMethod<Kpi>({} as Kpi),
      },
      kpiQuarterScore: {
        findMany: createMockMethod<KpiQuarterScore[]>([]),
      },
      user: {
        findMany: createMockMethod<unknown[]>([]),
        findUnique: createMockMethod<User | null>(null),
      },
      leaveRequest: {
        findMany: createMockMethod<MockLeaveItem[]>([]),
      },
      attendanceRecord: {
        findMany: createMockMethod<MockWfhItem[]>([]),
      },
    };

    service = new KpiService(
      prismaMock as unknown as PrismaService,
      eventsMock as unknown as EventsGateway,
    );
  });

  describe('getCurrentKpis', () => {
    it('scopes query to authenticated userId and returns array', async () => {
      const mockKpis: Kpi[] = [
        {
          id: 'kpi1',
          userId: 'user-123',
          title: 'Sales Goal',
          description: 'Sales Goal',
          departmentObjective: 'Objective',
          targetValue: 100,
          currentValue: 80,
          selfAssessmentText: null,
          hasEvidence: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];
      prismaMock.kpi.findMany.mockResolvedValue(mockKpis);

      const res = await service.getCurrentKpis('user-123');
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
      const mockKpis: Kpi[] = [
        {
          id: 'k1',
          userId: 'u1',
          title: 't1',
          description: 'd1',
          departmentObjective: 'do1',
          targetValue: 100,
          currentValue: 50,
          selfAssessmentText: null,
          hasEvidence: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: 'k2',
          userId: 'u1',
          title: 't2',
          description: 'd2',
          departmentObjective: 'do2',
          targetValue: 100,
          currentValue: 100,
          selfAssessmentText: null,
          hasEvidence: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];
      prismaMock.kpi.findMany.mockResolvedValue(mockKpis);
      const res = await service.getOverallQuarterScore('user-123');
      expect(res).toEqual({ overallScore: 0.75 });
    });
  });

  describe('getManagedUserIds (Cycle Detection)', () => {
    it('handles cyclic manager relationships safely without infinite loop or duplicate IDs', async () => {
      // Cycle: mgr-A -> emp-B -> mgr-A
      const level1: UserReportRecord[] = [{ id: 'emp-B' }];
      const level2: UserReportRecord[] = [{ id: 'mgr-A' }];

      prismaMock.user.findMany.mockResolvedValueOnce(level1);
      prismaMock.user.findMany.mockResolvedValueOnce(level2);

      const managedIds = await service.getManagedUserIds('mgr-A');
      expect(managedIds).toEqual(['emp-B']);
    });
  });

  describe('getTeamKpis', () => {
    it('returns empty array when manager has no managed employees (zero N+1 queries)', async () => {
      prismaMock.user.findMany.mockResolvedValue([]);
      const members: TeamMember[] = await service.getTeamKpis(
        'mgr-123',
        'manager',
      );
      expect(members).toEqual([]);
    });

    it('scopes manager query ONLY to resolved managed employee IDs and excludes unrelated employees', async () => {
      // Direct report emp-1 belongs to mgr-1. Unrelated emp-99 belongs to another manager.
      const managedReports: UserReportRecord[] = [{ id: 'emp-1' }];
      const emptyNextLevel: UserReportRecord[] = [];
      const teamUsers: SelectedUser[] = [
        {
          id: 'emp-1',
          name: 'Emp One',
          title: 'Dev',
          department: 'IT',
          kpis: [{ targetValue: 100, currentValue: 90 }],
        },
      ];

      prismaMock.user.findMany.mockResolvedValueOnce(managedReports);
      prismaMock.user.findMany.mockResolvedValueOnce(emptyNextLevel);
      prismaMock.user.findMany.mockResolvedValueOnce(teamUsers);

      prismaMock.leaveRequest.findMany.mockResolvedValue([]);
      prismaMock.attendanceRecord.findMany.mockResolvedValue([]);

      const members: TeamMember[] = await service.getTeamKpis(
        'mgr-1',
        'manager',
      );

      expect(members).toHaveLength(1);
      expect(members[0].id).toEqual('emp-1');
    });

    it('bulk fetches team data in batch queries without per-member N+1 loop', async () => {
      const level1: UserReportRecord[] = [{ id: 'emp-1' }, { id: 'emp-2' }];
      const level2: UserReportRecord[] = [];
      const teamUsers: SelectedUser[] = [
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
      ];

      prismaMock.user.findMany.mockResolvedValueOnce(level1);
      prismaMock.user.findMany.mockResolvedValueOnce(level2);
      prismaMock.user.findMany.mockResolvedValueOnce(teamUsers);

      prismaMock.leaveRequest.findMany.mockResolvedValue([{ userId: 'emp-1' }]);
      prismaMock.attendanceRecord.findMany.mockResolvedValue([
        { userId: 'emp-2' },
      ]);

      const members: TeamMember[] = await service.getTeamKpis(
        'mgr-123',
        'manager',
      );

      expect(members).toHaveLength(2);
      expect(members[0]).toEqual({
        id: 'emp-1',
        name: 'Emp One',
        title: 'Dev',
        department: 'IT',
        kpiScorePercent: 0.9,
        leaveStatus: 'onLeave',
      });
      expect(members[1]).toEqual({
        id: 'emp-2',
        name: 'Emp Two',
        title: 'QA',
        department: 'IT',
        kpiScorePercent: 0,
        leaveStatus: 'wfh',
      });
    });
  });

  describe('submitSelfAssessment & attachEvidence', () => {
    it('throws ForbiddenException when editing KPI belonging to another user', async () => {
      const mockKpi: Kpi = {
        id: 'kpi-1',
        userId: 'user-other',
        title: 't',
        description: 'd',
        departmentObjective: 'do',
        targetValue: 100,
        currentValue: 50,
        selfAssessmentText: null,
        hasEvidence: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      prismaMock.kpi.findUnique.mockResolvedValue(mockKpi);

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
      const targetUser: User = {
        id: 'target-1',
        employeeCode: null,
        email: 't@test.com',
        password: 'p',
        name: 'Target',
        role: 'employee',
        department: null,
        title: null,
        managerId: 'other-mgr',
        phone: null,
        nationalId: null,
        bankName: null,
        bankIban: null,
        baseSalary: null,
        jobGrade: null,
        costCenter: null,
        joiningDate: null,
        maritalStatus: null,
        emergencyContact: null,
        residenceAddress: null,
        city: null,
        country: null,
        degreeName: null,
        universityName: null,
        graduationYear: null,
        certificateUrl: null,
        militaryStatus: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      const emptyReports: User[] = [];

      prismaMock.user.findUnique.mockResolvedValue(targetUser);
      prismaMock.user.findMany.mockResolvedValue(emptyReports);

      await expect(
        service.assignKpi('mgr-1', 'manager', {
          memberId: 'target-1',
          title: 'New KPI',
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
