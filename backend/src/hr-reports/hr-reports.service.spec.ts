import { Test, TestingModule } from '@nestjs/testing';
import { HrReportsService } from './hr-reports.service';
import { PrismaService } from '../prisma/prisma.service';
import { CompanyTimeService } from '../common/time/company-time.service';

describe('HrReportsService', () => {
  let service: HrReportsService;
  let prismaMock: {
    user: { findMany: jest.Mock };
    attendanceRecord: { findMany: jest.Mock };
    leaveRequest: { findMany: jest.Mock };
    companyHoliday: { findMany: jest.Mock };
    overtimeSession: { findMany: jest.Mock };
  };

  beforeEach(async () => {
    prismaMock = {
      user: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'user-1',
            employeeCode: 'EMP001',
            name: 'Ahmed Ali',
            department: 'Engineering',
          },
        ]),
      },
      attendanceRecord: { findMany: jest.fn().mockResolvedValue([]) },
      leaveRequest: { findMany: jest.fn().mockResolvedValue([]) },
      companyHoliday: { findMany: jest.fn().mockResolvedValue([]) },
      overtimeSession: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HrReportsService,
        CompanyTimeService,
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
      ],
    }).compile();

    service = module.get<HrReportsService>(HrReportsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should query attendance, leave, holidays with business dates and overtime with Cairo UTC range', async () => {
    await service.getMonthlyReport({ month: '2026-08' });

    expect(prismaMock.user.findMany).toHaveBeenCalled();
    expect(prismaMock.attendanceRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          date: {
            gte: new Date('2026-08-01'),
            lt: new Date('2026-09-01'),
          },
        }),
      }),
    );

    // Overtime sessions must be queried using Cairo month UTC range (2026-07-31T21:00:00.000Z to 2026-08-31T21:00:00.000Z)
    expect(prismaMock.overtimeSession.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          startedAt: {
            gte: new Date('2026-07-31T21:00:00.000Z'),
            lt: new Date('2026-08-31T21:00:00.000Z'),
          },
        }),
      }),
    );
  });
});
