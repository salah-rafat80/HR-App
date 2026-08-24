import {
  EGYPT_TIME_ZONE,
  isSameEgyptAttendanceDay,
  startOfEgyptAttendanceDay,
} from './egypt-time.util';

describe('Egypt time utility', () => {
  it('uses the required Egypt timezone identifier', () => {
    expect(EGYPT_TIME_ZONE).toBe('Africa/Cairo');
  });

  it('maps a UTC instant after Cairo midnight to the correct Egypt attendance date', () => {
    const afterCairoMidnight = new Date('2026-08-14T22:30:00.000Z');

    expect(startOfEgyptAttendanceDay(afterCairoMidnight).toISOString()).toBe(
      '2026-08-15T00:00:00.000Z',
    );
  });

  it('does not treat instants on opposite sides of Cairo midnight as one attendance day', () => {
    const beforeCairoMidnight = new Date('2026-08-14T20:30:00.000Z');
    const afterCairoMidnight = new Date('2026-08-14T22:30:00.000Z');

    expect(
      isSameEgyptAttendanceDay(beforeCairoMidnight, afterCairoMidnight),
    ).toBe(false);
  });

  it('treats different UTC dates in the same Cairo attendance day as equal', () => {
    const lateUtcPreviousDate = new Date('2026-08-14T22:30:00.000Z');
    const earlyUtcCurrentDate = new Date('2026-08-15T20:30:00.000Z');

    expect(
      isSameEgyptAttendanceDay(lateUtcPreviousDate, earlyUtcCurrentDate),
    ).toBe(true);
  });
});
