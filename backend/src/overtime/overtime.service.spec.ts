/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/unbound-method */
import { ConflictException, ForbiddenException } from '@nestjs/common';
import { OvertimeSessionStatus, OvertimeStatus } from '@prisma/client';
import { AttendanceService } from '../attendance/attendance.service';
import { Role } from '../auth/roles.enum';
import { EventsGateway } from '../events/events/events.gateway';
import { PrismaService } from '../prisma/prisma.service';
import { OvertimeService } from './overtime.service';
import {
  serverNow,
  startOfEgyptAttendanceDay,
} from '../common/time/egypt-time.util';

const employee = { userId: 'employee-1', role: Role.employee };
const teamLead = { userId: 'lead-1', role: Role.team_lead };
const hr = { userId: 'hr-1', role: Role.hr };

function nowRequestPayload() {
  // Use noon of Cairo today via ISO string to avoid midnight boundary issues.
  const now = serverNow();
  const d = startOfEgyptAttendanceDay(now);
  const start = new Date(d.getTime() + 12 * 60 * 60 * 1000);
  const end = new Date(d.getTime() + 14 * 60 * 60 * 1000);
  return {
    requestedStartAt: start.toISOString(),
    requestedEndAt: end.toISOString(),
    reason: 'Critical production support',
  };
}

function makeRequest(overrides: Record<string, unknown> = {}) {
  const now = serverNow();
  const today = startOfEgyptAttendanceDay(now);
  return {
    id: 'request-1',
    userId: employee.userId,
    attendanceRecordId: 'attendance-1',
    date: today,
    requestedStartAt: new Date(today.getTime() + 12 * 60 * 60 * 1000),
    requestedEndAt: new Date(today.getTime() + 13 * 60 * 60 * 1000),
    requestedMinutes: 60,
    hoursRequested: 1,
    reason: 'Critical production support',
    status: OvertimeStatus.pending_team_lead,
    teamLeadId: teamLead.userId,
    teamLeadDecisionAt: null,
    teamLeadComment: null,
    hrApproverId: null,
    hrDecisionAt: null,
    hrComment: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    user: { id: employee.userId, managerId: teamLead.userId },
    attendanceRecord: {
      id: 'attendance-1',
      clockInTime: new Date(Date.now() - 8 * 60 * 60 * 1000),
      clockOutTime: new Date(Date.now() - 5 * 60 * 1000),
    },
    session: null,
    ...overrides,
  };
}

function makePrisma() {
  const tx = {
    overtimeSession: {
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      findUniqueOrThrow: jest.fn(),
    },
    overtimeRequest: {
      update: jest.fn().mockResolvedValue({}),
    },
  };

  return {
    user: { findUnique: jest.fn() },
    attendanceRecord: { findUnique: jest.fn() },
    overtimeRequest: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      updateMany: jest.fn(),
    },
    overtimeSession: {
      create: jest.fn(),
      findUnique: jest.fn(),
    },
    $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) =>
      Promise.resolve(callback(tx)),
    ),
    tx,
  };
}

function makeAttendanceService() {
  return {
    checkGeofence: jest.fn().mockResolvedValue({
      withinRange: true,
      distanceMeters: 12,
      allowedRadiusMeters: 200,
      nearestBranch: 'Main Office',
    }),
  } as unknown as jest.Mocked<AttendanceService>;
}

describe('OvertimeService (unit)', () => {
  let prisma: ReturnType<typeof makePrisma>;
  let attendanceService: jest.Mocked<AttendanceService>;
  let events: jest.Mocked<EventsGateway>;
  let service: OvertimeService;

  beforeEach(() => {
    prisma = makePrisma();
    attendanceService = makeAttendanceService();
    events = { emitToUser: jest.fn() } as unknown as jest.Mocked<EventsGateway>;
    service = new OvertimeService(
      prisma as unknown as PrismaService,
      attendanceService,
      events,
    );
  });

  it('creates a request only for today with an open or completed normal attendance record', async () => {
    const payload = nowRequestPayload();
    const created = makeRequest({ status: OvertimeStatus.pending_team_lead });
    prisma.user.findUnique.mockResolvedValue({
      id: employee.userId,
      managerId: teamLead.userId,
      isActive: true,
    });
    prisma.attendanceRecord.findUnique.mockResolvedValue({
      id: 'attendance-1',
      clockInTime: new Date(),
    });
    prisma.overtimeRequest.create.mockResolvedValue(created);

    await expect(service.requestOvertime(employee, payload)).resolves.toBe(
      created,
    );

    expect(prisma.overtimeRequest.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: employee.userId,
          attendanceRecordId: 'attendance-1',
          teamLeadId: teamLead.userId,
          status: OvertimeStatus.pending_team_lead,
          requestedMinutes: 120,
        }),
      }),
    );
    expect(events.emitToUser).toHaveBeenCalledWith(
      employee.userId,
      'updated',
      expect.any(Object),
    );
  });

  it('rejects a request when normal attendance has not started', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: employee.userId,
      managerId: teamLead.userId,
      isActive: true,
    });
    prisma.attendanceRecord.findUnique.mockResolvedValue(null);

    await expect(
      service.requestOvertime(employee, nowRequestPayload()),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.overtimeRequest.create).not.toHaveBeenCalled();
  });

  it('prevents a team lead from approving a request outside their direct reports', async () => {
    prisma.overtimeRequest.findUnique.mockResolvedValue(
      makeRequest({
        teamLeadId: 'different-lead',
        user: { id: employee.userId, managerId: 'different-lead' },
      }),
    );

    await expect(
      service.approveAsTeamLead('request-1', teamLead, {}),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.overtimeRequest.updateMany).not.toHaveBeenCalled();
  });

  it('moves a direct-report request from team lead review to HR review', async () => {
    const pending = makeRequest();
    const updated = makeRequest({ status: OvertimeStatus.pending_hr });
    prisma.overtimeRequest.findUnique.mockResolvedValueOnce(pending);
    prisma.overtimeRequest.findUniqueOrThrow.mockResolvedValue(updated);
    prisma.overtimeRequest.updateMany.mockResolvedValue({ count: 1 });

    await expect(
      service.approveAsTeamLead('request-1', teamLead, { comment: 'Approved' }),
    ).resolves.toBe(updated);

    expect(prisma.overtimeRequest.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: 'request-1',
          status: OvertimeStatus.pending_team_lead,
          teamLeadId: teamLead.userId,
        }),
        data: expect.objectContaining({ status: OvertimeStatus.pending_hr }),
      }),
    );
  });

  it('refuses HR approval before the team lead stage is complete', async () => {
    prisma.overtimeRequest.findUnique.mockResolvedValue(makeRequest());

    await expect(
      service.approveAsHr('request-1', hr, {}),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.overtimeRequest.updateMany).not.toHaveBeenCalled();
  });

  it('does not start overtime before normal attendance is clocked out', async () => {
    prisma.overtimeRequest.findUnique.mockResolvedValue(
      makeRequest({
        status: OvertimeStatus.approved,
        attendanceRecord: {
          id: 'attendance-1',
          clockInTime: new Date(),
          clockOutTime: null,
        },
      }),
    );

    await expect(
      service.startSession('request-1', employee, {
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(attendanceService.checkGeofence).not.toHaveBeenCalled();
  });

  it('starts one geofenced session for the HR-approved employee request', async () => {
    prisma.overtimeRequest.findUnique.mockResolvedValue(
      makeRequest({ status: OvertimeStatus.approved }),
    );
    const session = {
      id: 'session-1',
      overtimeRequestId: 'request-1',
      userId: employee.userId,
      status: OvertimeSessionStatus.active,
    };
    prisma.overtimeSession.create.mockResolvedValue(session);

    await expect(
      service.startSession('request-1', employee, {
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
      }),
    ).resolves.toBe(session);

    expect(prisma.overtimeSession.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          overtimeRequestId: 'request-1',
          attendanceRecordId: 'attendance-1',
          startLocationLabel: 'Main Office',
          startDistanceMeters: 12,
        }),
      }),
    );
  });

  it('stores overtime session start time from the backend clock', async () => {
    const serverInstant = new Date('2026-08-15T18:30:00.000Z');
    jest.useFakeTimers().setSystemTime(serverInstant);

    try {
      prisma.overtimeRequest.findUnique.mockResolvedValue(
        makeRequest({ status: OvertimeStatus.approved }),
      );
      prisma.overtimeSession.create.mockResolvedValue({
        id: 'session-1',
        overtimeRequestId: 'request-1',
        userId: employee.userId,
        status: OvertimeSessionStatus.active,
      });

      await service.startSession('request-1', employee, {
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
      });

      expect(prisma.overtimeSession.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ startedAt: serverInstant }),
        }),
      );
    } finally {
      jest.useRealTimers();
    }
  });

  it('ends the active session once and marks the request completed atomically', async () => {
    const startedAt = new Date(Date.now() - 5 * 60 * 1000);
    prisma.overtimeSession.findUnique.mockResolvedValue({
      id: 'session-1',
      overtimeRequestId: 'request-1',
      userId: employee.userId,
      status: OvertimeSessionStatus.active,
      endedAt: null,
      startedAt,
      overtimeRequest: makeRequest({ status: OvertimeStatus.approved }),
    });
    const completed = {
      id: 'session-1',
      userId: employee.userId,
      status: OvertimeSessionStatus.completed,
      actualMinutes: 5,
    };
    prisma.tx.overtimeSession.findUniqueOrThrow.mockResolvedValue(completed);

    await expect(
      service.endSession('session-1', employee, {
        lat: 24.7136,
        lng: 46.6753,
        accuracy: 10,
      }),
    ).resolves.toBe(completed);

    expect(prisma.tx.overtimeSession.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: 'session-1',
          status: OvertimeSessionStatus.active,
        }),
        data: expect.objectContaining({
          status: OvertimeSessionStatus.completed,
          endLocationLabel: 'Main Office',
        }),
      }),
    );
    expect(prisma.tx.overtimeRequest.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'request-1' },
        data: { status: OvertimeStatus.completed },
      }),
    );
  });

  it('does not expose the approval inbox to ordinary employees', async () => {
    await expect(service.getPendingApprovals(employee)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
