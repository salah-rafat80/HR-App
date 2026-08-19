/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access */
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

  it('should categorize approved working-day leave correctly and set note to Approved Leave', async () => {
    prismaMock.leaveRequest.findMany.mockResolvedValue([
      {
        userId: 'user-1',
        overallStatus: 'approved',
        startDate: new Date('2026-08-05'),
        endDate: new Date('2026-08-05'),
      },
    ]);

    const report = await service.getMonthlyReport({ month: '2026-08' });
    const employee = report.employees.find(
      (emp) => emp.employeeId === 'user-1',
    );
    expect(employee).toBeDefined();

    // 2026-08-05 is Wednesday (working day). It should be categorized as leave.
    const leaveDayRow = employee.dailyRows.find(
      (row) => row.date.getUTCDate() === 5 && row.date.getUTCMonth() === 7,
    );
    expect(leaveDayRow).toBeDefined();
    expect(leaveDayRow.dayType).toBe('leave');
    expect(leaveDayRow.attendanceStatus).toBe('onLeave');
    expect(leaveDayRow.note).toBe('Approved Leave');

    // Total days in Aug = 31.
    // 4 Fridays (weekend).
    // 1 leave day.
    // Total working days evaluated in else branch = 31 - 4 - 1 = 26.
    // Since mock attendance is empty, these 26 are absent.
    // The leave day is NOT counted as absent.
    expect(employee.workingDays).toBe(26);
    expect(employee.absentDays).toBe(26);
    expect(employee.leaveDays).toBe(1);
  });
});
