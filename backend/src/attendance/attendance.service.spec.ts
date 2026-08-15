/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/unbound-method */
import {
  BadRequestException,
  ForbiddenException,
  ConflictException,
  ValidationPipe,
} from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { ClockInDto } from './dto/clock-in.dto';
import { NotificationService } from '../notifications/notification.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AttendanceStatus } from '@prisma/client';

function makeActiveBranch(
  overrides: Partial<{
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    radiusMeters: number;
    isActive: boolean;
  }> = {},
) {
  return {
    id: 'branch-1',
    name: 'Main Office',
    latitude: 24.7136,
    longitude: 46.6753,
    radiusMeters: 200,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function makePrisma(branchOverrides = {}) {
  return {
    officeBranch: {
      findMany: jest
        .fn()
        .mockResolvedValue([makeActiveBranch(branchOverrides)]),
    },
    attendanceRecord: {
      findFirst: jest.fn().mockResolvedValue(null),
      create: jest
        .fn()
        .mockImplementation((args: { data: Record<string, unknown> }) => ({
          id: 'rec-1',
          userId: 'user-1',
          date: new Date('2026-08-14'),
          clockInTime: new Date(),
          clockOutTime: null,
          status: 'present',
          locationLabel: (args.data.locationLabel as string) || 'Main Office',
          distanceMeters: 50,
          clockInLat: args.data.clockInLat,
          clockInLng: args.data.clockInLng,
          createdAt: new Date(),
          updatedAt: new Date(),
        })),
      update: jest.fn(),
    },
    leaveRequest: {
      findMany: jest.fn().mockResolvedValue([]),
    },
    user: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'user-1',
        fcmToken: null,
        branchId: 'branch-1',
        branch: makeActiveBranch(branchOverrides),
      }),
    },
    shiftInfo: { findFirst: jest.fn().mockResolvedValue(null) },
    overtimeRequest: { create: jest.fn() },
  };
}

function makeNotificationService(): jest.Mocked<NotificationService> {
  return {
    sendToDevice: jest.fn().mockResolvedValue(undefined),
    notifyLeaveApproved: jest.fn(),
    notifyLeaveRejected: jest.fn(),
    notifyNewLeaveRequest: jest.fn(),
    notifyOvertimeApproved: jest.fn(),
    notifyKpiUpdated: jest.fn(),
    onModuleInit: jest.fn(),
  } as unknown as jest.Mocked<NotificationService>;
}

function makeEventsGateway(): jest.Mocked<EventsGateway> {
  return { emitToUser: jest.fn() } as unknown as jest.Mocked<EventsGateway>;
}

describe('AttendanceService (unit)', () => {
  const INSIDE_LAT = 24.7136;
  const INSIDE_LNG = 46.6753;
  const INSIDE_ACCURACY = 10;

  const OUTSIDE_LAT = 24.719;
  const OUTSIDE_LNG = 46.6753;
  const OUTSIDE_ACCURACY = 10;

  const BOUNDARY_LAT = 24.7155;
  const BOUNDARY_LNG = 46.6753;
  const BOUNDARY_ACCURACY = 40;

  let service: AttendanceService;
  let prisma: ReturnType<typeof makePrisma>;
  let notifications: jest.Mocked<NotificationService>;
  let events: jest.Mocked<EventsGateway>;

  beforeEach(() => {
    prisma = makePrisma();
    notifications = makeNotificationService();
    events = makeEventsGateway();
    service = new AttendanceService(
      prisma as unknown as PrismaService,
      events,
      notifications,
    );
  });

  it('rejects NaN lat', async () => {
    await expect(
      service.checkGeofence('user-1', NaN, 46.6753, 10),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects Infinity lng', async () => {
    await expect(
      service.checkGeofence('user-1', 24.7136, Infinity, 10),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects lat out of range', async () => {
    await expect(
      service.checkGeofence('user-1', 91, 46.6753, 10),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects lng out of range', async () => {
    await expect(
      service.checkGeofence('user-1', 24.7136, -181, 10),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects non-positive accuracy', async () => {
    await expect(
      service.checkGeofence('user-1', 24.7136, 46.6753, 0),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects accuracy > 50m', async () => {
    await expect(
      service.checkGeofence('user-1', 24.7136, 46.6753, 51),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('returns withinRange=true for inside position', async () => {
    const result = await service.checkGeofence(
      'user-1',
      INSIDE_LAT,
      INSIDE_LNG,
      INSIDE_ACCURACY,
    );
    expect(result.withinRange).toBe(true);
    expect(result.nearestBranch).toBe('Main Office');
  });

  it('returns withinRange=false when outside geofence', async () => {
    const result = await service.checkGeofence(
      'user-1',
      OUTSIDE_LAT,
      OUTSIDE_LNG,
      OUTSIDE_ACCURACY,
    );
    expect(result.withinRange).toBe(false);
    expect(result.distanceMeters).toBeGreaterThan(200);
  });

  it('rejects boundary where distance + accuracy > radius', async () => {
    const result = await service.checkGeofence(
      'user-1',
      BOUNDARY_LAT,
      BOUNDARY_LNG,
      BOUNDARY_ACCURACY,
    );
    expect(result.withinRange).toBe(false);
  });

  it('rejects clockIn when outside geofence — no DB write', async () => {
    await expect(
      service.clockIn('user-1', {
        mode: AttendanceStatus.present,
        lat: OUTSIDE_LAT,
        lng: OUTSIDE_LNG,
        accuracy: OUTSIDE_ACCURACY,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);

    expect(prisma.attendanceRecord.create).not.toHaveBeenCalled();
    expect(prisma.attendanceRecord.update).not.toHaveBeenCalled();
  });

  it('saves record with branch label from geofence, not from client', async () => {
    const record = await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: INSIDE_LAT,
      lng: INSIDE_LNG,
      accuracy: INSIDE_ACCURACY,
    });

    expect(record.locationLabel).toBe('Main Office');
    expect(prisma.attendanceRecord.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ locationLabel: 'Main Office' }),
      }),
    );
  });

  it('uses the assigned branch even when another branch is physically closer', async () => {
    const assignedBranch = makeActiveBranch({
      id: 'branch-b',
      name: 'Main HQ',
      latitude: 24.7139,
      longitude: 46.6753,
      radiusMeters: 100,
    });
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      fcmToken: null,
      branchId: assignedBranch.id,
      branch: assignedBranch,
    });

    const res = await service.checkGeofence('user-1', 24.7136, 46.6753, 10);
    expect(res.withinRange).toBe(true);
    expect(res.nearestBranch).toBe('Main HQ');
    expect(res.allowedRadiusMeters).toBe(100);

    const record = await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: 24.7136,
      lng: 46.6753,
      accuracy: 10,
    });
    expect(record.locationLabel).toBe('Main HQ');
    expect(prisma.attendanceRecord.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ locationLabel: 'Main HQ' }),
      }),
    );
  });

  it('returns typed persisted record with required fields', async () => {
    const record = await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: INSIDE_LAT,
      lng: INSIDE_LNG,
      accuracy: INSIDE_ACCURACY,
    });

    expect(record).toHaveProperty('id');
    expect(record).toHaveProperty('date');
    expect(record).toHaveProperty('clockInTime');
    expect(record).toHaveProperty('status');
    expect(record).toHaveProperty('locationLabel');
    expect(record).toHaveProperty('distanceMeters');
    expect(record).not.toHaveProperty('fcmToken');
  });

  it('attempts FCM only after successful DB commit', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      fcmToken: 'device-token-abc',
      branchId: 'branch-1',
      branch: makeActiveBranch(),
    });

    await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: INSIDE_LAT,
      lng: INSIDE_LNG,
      accuracy: INSIDE_ACCURACY,
    });

    await new Promise((r) => setTimeout(r, 50));

    expect(prisma.attendanceRecord.create).toHaveBeenCalled();
    expect(notifications.sendToDevice).toHaveBeenCalledWith(
      expect.objectContaining({
        title: expect.stringContaining('تسجيل'),
        data: expect.objectContaining({ type: 'attendance_clock_in' }),
      }),
    );
  });

  it('FCM failure does not throw or roll back the attendance record', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      fcmToken: 'device-token',
      branchId: 'branch-1',
      branch: makeActiveBranch(),
    });
    notifications.sendToDevice.mockRejectedValue(
      new Error('FCM network error'),
    );

    await expect(
      service.clockIn('user-1', {
        mode: AttendanceStatus.present,
        lat: INSIDE_LAT,
        lng: INSIDE_LNG,
        accuracy: INSIDE_ACCURACY,
      }),
    ).resolves.toHaveProperty('id');
  });

  it('does not attempt FCM when user has no fcmToken', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      fcmToken: null,
      branchId: 'branch-1',
      branch: makeActiveBranch(),
    });

    await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: INSIDE_LAT,
      lng: INSIDE_LNG,
      accuracy: INSIDE_ACCURACY,
    });

    await new Promise((r) => setTimeout(r, 50));
    expect(notifications.sendToDevice).not.toHaveBeenCalled();
  });

  it('response does not contain fcmToken field', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      fcmToken: 'secret-token',
      branchId: 'branch-1',
      branch: makeActiveBranch(),
    });

    const record = await service.clockIn('user-1', {
      mode: AttendanceStatus.present,
      lat: INSIDE_LAT,
      lng: INSIDE_LNG,
      accuracy: INSIDE_ACCURACY,
    });

    const serialised = JSON.stringify(record);
    expect(serialised).not.toContain('fcmToken');
    expect(serialised).not.toContain('secret-token');
  });

  it('stores clock-in time from the backend clock and uses the Egypt attendance date', async () => {
    const serverInstant = new Date('2026-08-14T22:30:00.000Z');
    jest.useFakeTimers().setSystemTime(serverInstant);

    try {
      await service.clockIn('user-1', {
        mode: AttendanceStatus.present,
        lat: INSIDE_LAT,
        lng: INSIDE_LNG,
        accuracy: INSIDE_ACCURACY,
      });

      expect(prisma.attendanceRecord.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            clockInTime: serverInstant,
            date: new Date('2026-08-15T00:00:00.000Z'),
          }),
        }),
      );
    } finally {
      jest.useRealTimers();
    }
  });

  describe('Single-Shift Attendance Lifecycle Enforcement', () => {
    it('a) first clock-in succeeds when no record exists today', async () => {
      prisma.attendanceRecord.findFirst.mockResolvedValue(null);
      const record = await service.clockIn('user-1', {
        mode: AttendanceStatus.present,
        lat: INSIDE_LAT,
        lng: INSIDE_LNG,
        accuracy: INSIDE_ACCURACY,
      });
      expect(record.clockInTime).not.toBeNull();
      expect(prisma.attendanceRecord.create).toHaveBeenCalled();
    });

    it('b) duplicate clock-in while day is open returns 409 and does not update or send FCM', async () => {
      const existingOpenRecord = {
        id: 'rec-open',
        userId: 'user-1',
        date: new Date(),
        clockInTime: new Date(Date.now() - 3600000),
        clockOutTime: null,
        status: AttendanceStatus.present,
        locationLabel: 'Main Office',
        distanceMeters: 10,
      };
      prisma.attendanceRecord.findFirst.mockResolvedValue(
        existingOpenRecord as any,
      );

      await expect(
        service.clockIn('user-1', {
          mode: AttendanceStatus.present,
          lat: INSIDE_LAT,
          lng: INSIDE_LNG,
          accuracy: INSIDE_ACCURACY,
        }),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(prisma.attendanceRecord.update).not.toHaveBeenCalled();
      expect(prisma.attendanceRecord.create).not.toHaveBeenCalled();
      expect(notifications.sendToDevice).not.toHaveBeenCalled();
    });

    it('c) clock-out from an open record succeeds exactly once', async () => {
      const existingOpenRecord = {
        id: 'rec-open',
        userId: 'user-1',
        date: new Date(),
        clockInTime: new Date(Date.now() - 3600000),
        clockOutTime: null,
        status: AttendanceStatus.present,
        locationLabel: 'Main Office',
      };
      prisma.attendanceRecord.findFirst.mockResolvedValue(
        existingOpenRecord as any,
      );
      prisma.attendanceRecord.update.mockImplementation(
        (args: { data: { clockOutTime: Date } }) =>
          Promise.resolve({
            ...existingOpenRecord,
            clockOutTime: args.data.clockOutTime,
          } as any),
      );

      const updated = await service.clockOut('user-1');
      expect(updated.clockOutTime).not.toBeNull();
      expect(prisma.attendanceRecord.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'rec-open' },
          data: expect.objectContaining({ clockOutTime: expect.any(Date) }),
        }),
      );
    });

    it('d) duplicate clock-out returns 409 and preserves original clockOutTime', async () => {
      const closedRecord = {
        id: 'rec-closed',
        userId: 'user-1',
        date: new Date(),
        clockInTime: new Date(Date.now() - 7200000),
        clockOutTime: new Date(Date.now() - 3600000),
        status: AttendanceStatus.present,
        locationLabel: 'Main Office',
      };
      prisma.attendanceRecord.findFirst.mockResolvedValue(closedRecord as any);

      await expect(service.clockOut('user-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(prisma.attendanceRecord.update).not.toHaveBeenCalled();
    });

    it('e) clock-in after clock-out returns 409 and preserves original record', async () => {
      const closedRecord = {
        id: 'rec-closed',
        userId: 'user-1',
        date: new Date(),
        clockInTime: new Date(Date.now() - 7200000),
        clockOutTime: new Date(Date.now() - 3600000),
        status: AttendanceStatus.present,
        locationLabel: 'Main Office',
      };
      prisma.attendanceRecord.findFirst.mockResolvedValue(closedRecord as any);

      await expect(
        service.clockIn('user-1', {
          mode: AttendanceStatus.present,
          lat: INSIDE_LAT,
          lng: INSIDE_LNG,
          accuracy: INSIDE_ACCURACY,
        }),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(prisma.attendanceRecord.update).not.toHaveBeenCalled();
      expect(prisma.attendanceRecord.create).not.toHaveBeenCalled();
      expect(notifications.sendToDevice).not.toHaveBeenCalled();
    });

    it('f) all current-day lookups are scoped to the authenticated user', async () => {
      await service.getTodayStatus('user-999');
      expect(prisma.attendanceRecord.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ userId: 'user-999' }),
        }),
      );

      prisma.attendanceRecord.findFirst.mockClear();
      await expect(service.clockOut('user-888')).rejects.toThrow();
      expect(prisma.attendanceRecord.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ userId: 'user-888' }),
        }),
      );
    });
  });
});

describe('ClockInDto ValidationPipe (DTO validation)', () => {
  let target: ValidationPipe;

  beforeEach(() => {
    target = new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    });
  });

  const transform = (body: unknown) =>
    target.transform(body, { type: 'body', metatype: ClockInDto });

  it('accepts valid payload', async () => {
    const valid = {
      mode: 'present',
      lat: 24.7136,
      lng: 46.6753,
      accuracy: 10,
    };
    const dto = await transform(valid);
    expect(dto).toBeInstanceOf(ClockInDto);
  });

  it('rejects missing lat', async () => {
    await expect(
      transform({ mode: 'present', lng: 46.6753, accuracy: 10 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects missing lng', async () => {
    await expect(
      transform({ mode: 'present', lat: 24.7136, accuracy: 10 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects missing accuracy', async () => {
    await expect(
      transform({ mode: 'present', lat: 24.7136, lng: 46.6753 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects accuracy above 50', async () => {
    await expect(
      transform({ mode: 'present', lat: 24.7136, lng: 46.6753, accuracy: 51 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects zero or negative accuracy', async () => {
    await expect(
      transform({ mode: 'present', lat: 24.7136, lng: 46.6753, accuracy: 0 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects lat out of range', async () => {
    await expect(
      transform({ mode: 'present', lat: 91, lng: 46.6753, accuracy: 10 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects lng out of range', async () => {
    await expect(
      transform({ mode: 'present', lat: 24.7136, lng: 181, accuracy: 10 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects client-supplied locationLabel (forbidden non-whitelisted)', async () => {
    await expect(
      transform({
        mode: 'present',
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
        locationLabel: 'Hacker Office',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects a client-supplied attendance timestamp', async () => {
    await expect(
      transform({
        mode: 'present',
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
        clockInTime: '2000-01-01T00:00:00.000Z',
      }),
    ).rejects.toThrow(BadRequestException);
  });
});
