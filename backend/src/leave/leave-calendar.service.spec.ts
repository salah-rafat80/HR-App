/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-explicit-any, @typescript-eslint/unbound-method */
import { Test, TestingModule } from '@nestjs/testing';
import { LeaveCalendarService } from './leave-calendar.service';
import { PrismaService } from '../prisma/prisma.service';
import { CompanyTimeService } from '../common/time/company-time.service';

describe('LeaveCalendarService', () => {
  let service: LeaveCalendarService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LeaveCalendarService,
        CompanyTimeService,
        {
          provide: PrismaService,
          useValue: {
            companyHoliday: {
              findMany: jest.fn(),
              findFirst: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get<LeaveCalendarService>(LeaveCalendarService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should exclude Friday as weekend', async () => {
    // 2026-08-21 is Friday, 2026-08-22 is Saturday
    jest.spyOn(prisma.companyHoliday, 'findMany').mockResolvedValue([]);
    const days = await service.calculateWorkingDays(
      '2026-08-20',
      '2026-08-22',
      false,
    );
    // 2026-08-20 (Thursday) - working
    // 2026-08-21 (Friday) - weekend (excluded)
    // 2026-08-22 (Saturday) - working
    expect(days.toString()).toBe('2');
  });

  it('should exclude official company holidays', async () => {
    // 2026-08-20 is Thursday, we mock it as a holiday
    jest.spyOn(prisma.companyHoliday, 'findMany').mockResolvedValue([
      {
        id: 'holiday-1',
        date: new Date('2026-08-20'),
        name: 'Revolution Day',
        isActive: true,
        createdById: 'admin',
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ]);

    const days = await service.calculateWorkingDays(
      '2026-08-19',
      '2026-08-20',
      false,
    );
    // 2026-08-19 (Wednesday) - working
    // 2026-08-20 (Thursday) - holiday (excluded)
    expect(days.toString()).toBe('1');
  });

  it('should return 0.5 for half day if on a working day', async () => {
    jest.spyOn(prisma.companyHoliday, 'findFirst').mockResolvedValue(null);
    const days = await service.calculateWorkingDays(
      '2026-08-20',
      '2026-08-20',
      true,
    );
    expect(days.toString()).toBe('0.5');
  });

  it('should throw error for half day if start date is not equal to end date', async () => {
    await expect(
      service.calculateWorkingDays('2026-08-20', '2026-08-21', true),
    ).rejects.toThrow('HALFDAY_MUST_SPAN_ONE_DAY');
  });

  it('should throw error for half day if on Friday weekend', async () => {
    jest.spyOn(service as any, 'isWorkingDay').mockResolvedValue(false);

    await expect(
      service.calculateWorkingDays('2026-08-21', '2026-08-21', true),
    ).rejects.toThrow('HALFDAY_MUST_BE_ON_WORKING_DAY');
  });
});
