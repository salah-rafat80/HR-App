import { CompanyTimeService, COMPANY_TIMEZONE } from './company-time.service';

describe('CompanyTimeService — Africa/Cairo Server-Authoritative Time Contract', () => {
  let service: CompanyTimeService;

  beforeEach(() => {
    service = new CompanyTimeService();
  });

  it('should format company business date correctly for summer instant (UTC+3)', () => {
    // 2026-08-15T09:25:00.000Z -> In Cairo (UTC+3) this is 12:25:00 on 2026-08-15
    const utcInstant = new Date('2026-08-15T09:25:00.000Z');
    const dateStr = service.companyBusinessDate(utcInstant);
    expect(dateStr).toBe('2026-08-15');
    expect(service.formatCompanyDateTime(utcInstant)).toBe(
      '2026-08-15 12:25:00',
    );
  });

  it('should keep date on prior Cairo day before Cairo midnight in summer', () => {
    // 2026-08-15T20:59:00.000Z -> In Cairo (UTC+3) this is 23:59:00 on 2026-08-15
    const instant = new Date('2026-08-15T20:59:00.000Z');
    expect(service.companyBusinessDate(instant)).toBe('2026-08-15');
  });

  it('should map to next Cairo business date after Cairo midnight while still prior UTC date', () => {
    // 2026-08-15T21:05:00.000Z -> In Cairo (UTC+3) this is 2026-08-16 00:05:00
    const instant = new Date('2026-08-15T21:05:00.000Z');
    expect(service.companyBusinessDate(instant)).toBe('2026-08-16');
  });

  it('should automatically handle winter offset (UTC+2) without hardcoded offsets', () => {
    // 2026-01-15T12:00:00.000Z -> In Cairo winter (UTC+2) this is 14:00:00 on 2026-01-15
    const winterInstant = new Date('2026-01-15T12:00:00.000Z');
    expect(service.companyBusinessDate(winterInstant)).toBe('2026-01-15');
    expect(service.formatCompanyDateTime(winterInstant)).toBe(
      '2026-01-15 14:00:00',
    );
  });

  it('should correctly identify a Friday in Africa/Cairo and handle boundary hours', () => {
    // 2026-08-14 is a Friday in Cairo.
    // 2026-08-13T21:30:00.000Z -> Cairo time: 2026-08-14 00:30:00 (Friday!)
    const fridayInstant = new Date('2026-08-13T21:30:00.000Z');
    expect(service.isCompanyFriday(fridayInstant)).toBe(true);

    // 2026-08-14T21:30:00.000Z -> Cairo time: 2026-08-15 00:30:00 (Saturday!)
    const saturdayInstant = new Date('2026-08-14T21:30:00.000Z');
    expect(service.isCompanyFriday(saturdayInstant)).toBe(false);
  });

  it('should return correct start and end UTC bounds for Cairo business day', () => {
    const startUtc = service.startOfCompanyBusinessDay('2026-08-15');
    const endUtc = service.endOfCompanyBusinessDay('2026-08-15');

    // Cairo is UTC+3 in August: 00:00:00 Cairo = 2026-08-14T21:00:00.000Z
    expect(startUtc.toISOString()).toBe('2026-08-14T21:00:00.000Z');
    // 23:59:59.999 Cairo = 2026-08-15T20:59:59.999Z
    expect(endUtc.toISOString()).toBe('2026-08-15T20:59:59.999Z');
  });

  it('should return correct month range in UTC for Cairo year and month', () => {
    // August 2026 in Cairo (UTC+3)
    const { startUtc, endExclusiveUtc } = service.companyMonthRange(2026, 8);
    // Start of Aug 1 in Cairo = 2026-07-31T21:00:00.000Z
    expect(startUtc.toISOString()).toBe('2026-07-31T21:00:00.000Z');
    // Start of Sep 1 in Cairo = 2026-08-31T21:00:00.000Z
    expect(endExclusiveUtc.toISOString()).toBe('2026-08-31T21:00:00.000Z');
  });

  it('should parse Egypt local date-time string into correct UTC instant', () => {
    // Planned input '2026-08-15 17:00' in Cairo (UTC+3) -> 14:00:00.000Z UTC
    const utcDate = service.parseCompanyLocalDateTime('2026-08-15 17:00');
    expect(utcDate.toISOString()).toBe('2026-08-15T14:00:00.000Z');
  });

  it('should serialize Date objects to full ISO-8601 strings ending in Z', () => {
    const d = new Date('2026-08-15T09:25:00.000Z');
    const serialized = service.serializeUtc(d);
    expect(serialized).toBe('2026-08-15T09:25:00.000Z');
    expect(serialized?.endsWith('Z')).toBe(true);
  });
});
