export const EGYPT_TIME_ZONE = 'Africa/Cairo';

interface EgyptDateParts {
  year: number;
  month: number;
  day: number;
}

/**
 * Returns the current instant from the backend process. It must never be
 * replaced with a client-supplied timestamp for attendance or overtime events.
 */
export function serverNow(): Date {
  return new Date();
}

/**
 * Converts an instant to Egypt's Gregorian calendar date without depending on
 * the host machine's timezone. The returned Date is UTC midnight solely to
 * represent a PostgreSQL DATE value consistently.
 */
export function startOfEgyptAttendanceDay(at: Date = serverNow()): Date {
  const { year, month, day } = egyptDateParts(at);
  return new Date(Date.UTC(year, month - 1, day));
}

export function isSameEgyptAttendanceDay(left: Date, right: Date): boolean {
  const leftDay = startOfEgyptAttendanceDay(left);
  const rightDay = startOfEgyptAttendanceDay(right);
  return leftDay.getTime() === rightDay.getTime();
}

export function formatEgyptTime(at: Date): string {
  return at.toLocaleTimeString('ar-EG', {
    timeZone: EGYPT_TIME_ZONE,
    hour: '2-digit',
    minute: '2-digit',
  });
}

function egyptDateParts(at: Date): EgyptDateParts {
  const parts = new Intl.DateTimeFormat('en-US-u-ca-gregory-nu-latn', {
    timeZone: EGYPT_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(at);

  const values = Object.fromEntries(
    parts
      .filter((part) => part.type !== 'literal')
      .map((part) => [part.type, part.value]),
  );

  return {
    year: Number(values.year),
    month: Number(values.month),
    day: Number(values.day),
  };
}
