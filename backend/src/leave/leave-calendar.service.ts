import { Injectable, BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CompanyTimeService } from '../common/time/company-time.service';
import { DateTime } from 'luxon';

@Injectable()
export class LeaveCalendarService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly companyTime: CompanyTimeService,
  ) {}

  /**
   * Calculates the number of working days between two Cairo dates (inclusive).
   * Excludes Fridays and active company holidays.
   * Returns a Decimal.
   */
  async calculateWorkingDays(
    startDateStr: string,
    endDateStr: string,
    isHalfDay: boolean,
  ): Promise<Prisma.Decimal> {
    const startDt = DateTime.fromISO(startDateStr, {
      zone: 'Africa/Cairo',
    }).startOf('day');
    const endDt = DateTime.fromISO(endDateStr, {
      zone: 'Africa/Cairo',
    }).startOf('day');

    if (!startDt.isValid || !endDt.isValid) {
      throw new BadRequestException('INVALID_DATE_FORMAT');
    }

    if (endDt < startDt) {
      throw new BadRequestException('END_DATE_BEFORE_START_DATE');
    }

    if (isHalfDay) {
      if (startDateStr !== endDateStr) {
        throw new BadRequestException('HALFDAY_MUST_SPAN_ONE_DAY');
      }
      // Check if the single day is a working day
      const isWorkDay = await this.isWorkingDay(startDateStr);
      if (!isWorkDay) {
        throw new BadRequestException('HALFDAY_MUST_BE_ON_WORKING_DAY');
      }
      return new Prisma.Decimal('0.5');
    }

    // Load active holidays overlapping the range
    const holidays = await this.prisma.companyHoliday.findMany({
      where: {
        isActive: true,
        date: {
          gte: startDt.toJSDate(),
          lte: endDt.toJSDate(),
        },
      },
    });

    const holidayDates = new Set(
      holidays.map((h) => this.companyTime.companyBusinessDate(h.date)),
    );

    let workingDays = 0;
    let current = startDt;

    while (current <= endDt) {
      const dateStr = current.toISODate()!;
      const isFriday = current.weekday === 5; // Friday is weekend in Egypt
      const isHoliday = holidayDates.has(dateStr);

      if (!isFriday && !isHoliday) {
        workingDays++;
      }

      current = current.plus({ days: 1 });
    }

    return new Prisma.Decimal(workingDays.toString());
  }

  /**
   * Helper to check if a single date string is a working day.
   */
  private async isWorkingDay(dateStr: string): Promise<boolean> {
    const dt = DateTime.fromISO(dateStr, { zone: 'Africa/Cairo' }).startOf(
      'day',
    );
    if (dt.weekday === 5) return false;

    const holiday = await this.prisma.companyHoliday.findFirst({
      where: {
        isActive: true,
        date: dt.toJSDate(),
      },
    });

    return !holiday;
  }
}
