import { Injectable } from '@nestjs/common';
import { DateTime } from 'luxon';

export const COMPANY_TIMEZONE = 'Africa/Cairo';

@Injectable()
export class CompanyTimeService {
  /**
   * Returns the current server instant in UTC.
   */
  serverNowUtc(): Date {
    return new Date();
  }

  /**
   * Returns the current time as a Luxon DateTime in Africa/Cairo.
   */
  companyNow(): DateTime {
    return DateTime.now().setZone(COMPANY_TIMEZONE);
  }

  /**
   * Derives the Egypt business date string ('YYYY-MM-DD') for a given UTC instant or Date.
   */
  companyBusinessDate(instant?: Date | string | number): string {
    const dt = instant
      ? DateTime.fromJSDate(new Date(instant)).setZone(COMPANY_TIMEZONE)
      : this.companyNow();
    return dt.toISODate()!;
  }

  /**
   * Returns the start of the Egypt business day (00:00:00.000 in Cairo) as a UTC Date instant.
   */
  startOfCompanyBusinessDay(dateStr: string): Date {
    const dt = DateTime.fromISO(dateStr, { zone: COMPANY_TIMEZONE }).startOf(
      'day',
    );
    if (!dt.isValid) {
      throw new Error(
        `Invalid date string for startOfCompanyBusinessDay: ${dateStr}`,
      );
    }
    return dt.toJSDate();
  }

  /**
   * Returns the end of the Egypt business day (23:59:59.999 in Cairo) as a UTC Date instant.
   */
  endOfCompanyBusinessDay(dateStr: string): Date {
    const dt = DateTime.fromISO(dateStr, { zone: COMPANY_TIMEZONE }).endOf(
      'day',
    );
    if (!dt.isValid) {
      throw new Error(
        `Invalid date string for endOfCompanyBusinessDay: ${dateStr}`,
      );
    }
    return dt.toJSDate();
  }

  /**
   * Checks if two instants fall on the same Egypt business day.
   */
  isSameCompanyBusinessDay(a: Date | string, b: Date | string): boolean {
    return this.companyBusinessDate(a) === this.companyBusinessDate(b);
  }

  /**
   * Checks if a given instant corresponds to a Friday in Africa/Cairo.
   * Luxon weekday: 1 = Monday, 5 = Friday, 7 = Sunday.
   */
  isCompanyFriday(instant?: Date | string): boolean {
    const dt = instant
      ? DateTime.fromJSDate(new Date(instant)).setZone(COMPANY_TIMEZONE)
      : this.companyNow();
    return dt.weekday === 5;
  }

  /**
   * Returns the start and end exclusive UTC instants for a given Cairo year & month (1-indexed).
   */
  companyMonthRange(
    year: number,
    month: number,
  ): { startUtc: Date; endExclusiveUtc: Date } {
    const startDt = DateTime.fromObject(
      { year, month, day: 1 },
      { zone: COMPANY_TIMEZONE },
    ).startOf('day');
    const endExclusiveDt = startDt.plus({ months: 1 });
    return {
      startUtc: startDt.toJSDate(),
      endExclusiveUtc: endExclusiveDt.toJSDate(),
    };
  }

  /**
   * Parses an Egypt local date-time string (e.g., '2026-08-15 14:30' or '2026-08-15T14:30:00')
   * into a UTC Date instant.
   */
  parseCompanyLocalDateTime(value: string): Date {
    let dt = DateTime.fromISO(value, { zone: COMPANY_TIMEZONE });
    if (!dt.isValid) {
      dt = DateTime.fromFormat(value, 'yyyy-MM-dd HH:mm:ss', {
        zone: COMPANY_TIMEZONE,
      });
      if (!dt.isValid) {
        dt = DateTime.fromFormat(value, 'yyyy-MM-dd HH:mm', {
          zone: COMPANY_TIMEZONE,
        });
      }
    }
    if (!dt.isValid) {
      throw new Error(
        `Invalid local date-time format for Cairo timezone: ${value}`,
      );
    }
    return dt.toJSDate();
  }

  /**
   * Serializes a Date object to a full ISO-8601 UTC string ending in 'Z'.
   */
  serializeUtc(value: Date | string | null | undefined): string | null {
    if (!value) return null;
    const dateObj = typeof value === 'string' ? new Date(value) : value;
    return dateObj.toISOString();
  }

  /**
   * Formats an instant for human display in Africa/Cairo (e.g., 'YYYY-MM-DD HH:mm:ss').
   */
  formatCompanyDateTime(
    instant: Date | string,
    format = 'yyyy-MM-dd HH:mm:ss',
  ): string {
    const dt = DateTime.fromJSDate(new Date(instant)).setZone(COMPANY_TIMEZONE);
    return dt.toFormat(format);
  }

  companyBusinessYear(instant?: Date | string | number): number {
    const dateStr = this.companyBusinessDate(instant);
    return DateTime.fromISO(dateStr).year;
  }
}
