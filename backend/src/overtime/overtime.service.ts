import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OvertimeSessionStatus, OvertimeStatus, Prisma } from '@prisma/client';
import { Role } from '../auth/roles.enum';
import { AttendanceService } from '../attendance/attendance.service';
import { EventsGateway } from '../events/events/events.gateway';
import { PrismaService } from '../prisma/prisma.service';
import { OvertimeDecisionDto } from './dto/decision.dto';
import { OvertimeLocationDto } from './dto/overtime-location.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';
import {
  isSameEgyptAttendanceDay,
  serverNow,
  startOfEgyptAttendanceDay,
} from '../common/time/egypt-time.util';

const MAX_REQUESTED_OVERTIME_MINUTES = 12 * 60;

interface OvertimeActor {
  userId: string;
  role: string;
}

@Injectable()
export class OvertimeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly attendanceService: AttendanceService,
    private readonly events: EventsGateway,
  ) {}

  async requestOvertime(actor: OvertimeActor, data: RequestOvertimeDto) {
    const now = serverNow();
    const requestedStartAt = new Date(data.requestedStartAt);
    const requestedEndAt = new Date(data.requestedEndAt);
    const today = startOfEgyptAttendanceDay(now);

    if (!isSameEgyptAttendanceDay(requestedStartAt, now)) {
      throw new BadRequestException(
        'Overtime requests must be for the current Egypt attendance day',
      );
    }

    if (!isSameEgyptAttendanceDay(requestedEndAt, requestedStartAt)) {
      throw new BadRequestException(
        'Overtime request start and end must be on the same Egypt attendance day',
      );
    }

    const reason = data.reason.trim();
    if (!reason) {
      throw new BadRequestException('Overtime reason cannot be blank');
    }

    const requestedMinutes = Math.round(
      (requestedEndAt.getTime() - requestedStartAt.getTime()) / 60000,
    );
    if (
      !Number.isInteger(requestedMinutes) ||
      requestedMinutes < 1 ||
      requestedMinutes > MAX_REQUESTED_OVERTIME_MINUTES
    ) {
      throw new BadRequestException(
        `Requested overtime must be between 1 and ${MAX_REQUESTED_OVERTIME_MINUTES} minutes`,
      );
    }

    const [employee, attendance] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: actor.userId },
        select: { id: true, managerId: true, isActive: true },
      }),
      this.prisma.attendanceRecord.findUnique({
        where: {
          AttendanceRecord_userId_date_key: {
            userId: actor.userId,
            date: today,
          },
        },
        select: { id: true, clockInTime: true },
      }),
    ]);

    if (!employee?.isActive) {
      throw new ForbiddenException('Employee account is inactive');
    }
    if (!employee.managerId) {
      throw new ConflictException(
        'Employee has no assigned team lead for overtime approval',
      );
    }
    if (!attendance?.clockInTime) {
      throw new ConflictException(
        'A normal clock-in is required before requesting overtime',
      );
    }

    try {
      const created = await this.prisma.overtimeRequest.create({
        data: {
          userId: actor.userId,
          attendanceRecordId: attendance.id,
          date: today,
          requestedStartAt,
          requestedEndAt,
          requestedMinutes,
          hoursRequested: requestedMinutes / 60,
          reason,
          status: OvertimeStatus.pending_team_lead,
          teamLeadId: employee.managerId,
        },
      });

      this.events.emitToUser(actor.userId, 'updated', {
        type: 'OvertimeRequest',
        data: created,
      });
      return created;
    } catch (error: unknown) {
      if (this.isUniqueConstraintError(error)) {
        throw new ConflictException(
          'An active overtime request already exists for today',
        );
      }
      throw error;
    }
  }

  async getMyRequests(userId: string) {
    return this.prisma.overtimeRequest.findMany({
      where: { userId },
      include: { session: true },
      orderBy: { createdAt: 'desc' },
      take: 60,
    });
  }

  async getPendingApprovals(actor: OvertimeActor) {
    const include = {
      user: {
        select: {
          id: true,
          employeeCode: true,
          name: true,
          department: true,
          managerId: true,
        },
      },
      attendanceRecord: {
        select: { id: true, clockInTime: true, clockOutTime: true },
      },
      session: true,
    };

    if (actor.role === String(Role.team_lead)) {
      return this.prisma.overtimeRequest.findMany({
        where: {
          status: OvertimeStatus.pending_team_lead,
          teamLeadId: actor.userId,
          user: { managerId: actor.userId },
        },
        include,
        orderBy: { createdAt: 'asc' },
      });
    }

    if (this.isHrApprover(actor.role)) {
      return this.prisma.overtimeRequest.findMany({
        where: { status: OvertimeStatus.pending_hr },
        include,
        orderBy: { createdAt: 'asc' },
      });
    }

    throw new ForbiddenException('This role has no overtime approval inbox');
  }

  async approveAsTeamLead(
    requestId: string,
    actor: OvertimeActor,
    data: OvertimeDecisionDto,
  ) {
    if (actor.role !== String(Role.team_lead)) {
      throw new ForbiddenException('Only a team lead can take this decision');
    }

    const request = await this.findRequestForDecision(requestId);
    if (
      request.status !== OvertimeStatus.pending_team_lead ||
      request.teamLeadId !== actor.userId ||
      request.user.managerId !== actor.userId
    ) {
      throw new ForbiddenException(
        'You cannot approve this overtime request at the team lead stage',
      );
    }

    const result = await this.prisma.overtimeRequest.updateMany({
      where: {
        id: requestId,
        status: OvertimeStatus.pending_team_lead,
        teamLeadId: actor.userId,
      },
      data: {
        status: OvertimeStatus.pending_hr,
        teamLeadDecisionAt: serverNow(),
        teamLeadComment: this.normaliseComment(data.comment),
      },
    });
    if (result.count !== 1) {
      throw new ConflictException('Overtime request state changed; refresh it');
    }

    return this.publishRequestUpdate(requestId);
  }

  async rejectAsTeamLead(
    requestId: string,
    actor: OvertimeActor,
    data: OvertimeDecisionDto,
  ) {
    if (actor.role !== String(Role.team_lead)) {
      throw new ForbiddenException('Only a team lead can take this decision');
    }

    const request = await this.findRequestForDecision(requestId);
    if (
      request.status !== OvertimeStatus.pending_team_lead ||
      request.teamLeadId !== actor.userId ||
      request.user.managerId !== actor.userId
    ) {
      throw new ForbiddenException(
        'You cannot reject this overtime request at the team lead stage',
      );
    }

    const result = await this.prisma.overtimeRequest.updateMany({
      where: {
        id: requestId,
        status: OvertimeStatus.pending_team_lead,
        teamLeadId: actor.userId,
      },
      data: {
        status: OvertimeStatus.rejected_by_team_lead,
        teamLeadDecisionAt: serverNow(),
        teamLeadComment: this.normaliseComment(data.comment),
      },
    });
    if (result.count !== 1) {
      throw new ConflictException('Overtime request state changed; refresh it');
    }

    return this.publishRequestUpdate(requestId);
  }

  async approveAsHr(
    requestId: string,
    actor: OvertimeActor,
    data: OvertimeDecisionDto,
  ) {
    this.assertHrApprover(actor.role);

    const request = await this.findRequestForDecision(requestId);
    if (request.status !== OvertimeStatus.pending_hr) {
      throw new ConflictException('Request is not pending HR approval');
    }

    const result = await this.prisma.overtimeRequest.updateMany({
      where: { id: requestId, status: OvertimeStatus.pending_hr },
      data: {
        status: OvertimeStatus.approved,
        hrApproverId: actor.userId,
        hrDecisionAt: serverNow(),
        hrComment: this.normaliseComment(data.comment),
      },
    });
    if (result.count !== 1) {
      throw new ConflictException('Overtime request state changed; refresh it');
    }

    return this.publishRequestUpdate(requestId);
  }

  async rejectAsHr(
    requestId: string,
    actor: OvertimeActor,
    data: OvertimeDecisionDto,
  ) {
    this.assertHrApprover(actor.role);

    const request = await this.findRequestForDecision(requestId);
    if (request.status !== OvertimeStatus.pending_hr) {
      throw new ConflictException('Request is not pending HR approval');
    }

    const result = await this.prisma.overtimeRequest.updateMany({
      where: { id: requestId, status: OvertimeStatus.pending_hr },
      data: {
        status: OvertimeStatus.rejected_by_hr,
        hrApproverId: actor.userId,
        hrDecisionAt: serverNow(),
        hrComment: this.normaliseComment(data.comment),
      },
    });
    if (result.count !== 1) {
      throw new ConflictException('Overtime request state changed; refresh it');
    }

    return this.publishRequestUpdate(requestId);
  }

  async startSession(
    requestId: string,
    actor: OvertimeActor,
    data: OvertimeLocationDto,
  ) {
    const now = serverNow();
    const request = await this.prisma.overtimeRequest.findUnique({
      where: { id: requestId },
      include: {
        attendanceRecord: true,
        session: true,
      },
    });

    if (!request) throw new NotFoundException('Overtime request not found');
    if (request.userId !== actor.userId) {
      throw new ForbiddenException('You can start only your own overtime');
    }
    if (request.status !== OvertimeStatus.approved) {
      throw new ConflictException('Overtime request is not HR approved');
    }
    if (request.session) {
      throw new ConflictException(
        'An overtime session already exists for request',
      );
    }
    if (!this.isToday(request.date, now)) {
      throw new ConflictException(
        'Overtime can start only on its request date',
      );
    }
    if (!request.attendanceRecord?.clockOutTime) {
      throw new ConflictException(
        'Normal attendance must be clocked out before overtime starts',
      );
    }

    const geofence = await this.attendanceService.checkGeofence(
      actor.userId,
      data.lat,
      data.lng,
      data.accuracy,
    );
    if (!geofence.withinRange) {
      throw new ForbiddenException(
        `You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, outside the allowed range (${geofence.allowedRadiusMeters}m).`,
      );
    }

    try {
      const session = await this.prisma.overtimeSession.create({
        data: {
          overtimeRequestId: request.id,
          userId: actor.userId,
          attendanceRecordId: request.attendanceRecord.id,
          status: OvertimeSessionStatus.active,
          startedAt: now,
          startLocationLabel: geofence.nearestBranch,
          startLatitude: data.lat,
          startLongitude: data.lng,
          startGpsAccuracy: data.accuracy,
          startDistanceMeters: geofence.distanceMeters,
        },
      });
      this.events.emitToUser(actor.userId, 'updated', {
        type: 'OvertimeSession',
        data: session,
      });
      return session;
    } catch (error: unknown) {
      if (this.isUniqueConstraintError(error)) {
        throw new ConflictException(
          'An overtime session already exists for request',
        );
      }
      throw error;
    }
  }

  async endSession(
    sessionId: string,
    actor: OvertimeActor,
    data: OvertimeLocationDto,
  ) {
    const session = await this.prisma.overtimeSession.findUnique({
      where: { id: sessionId },
      include: { overtimeRequest: true },
    });

    if (!session) throw new NotFoundException('Overtime session not found');
    if (session.userId !== actor.userId) {
      throw new ForbiddenException('You can end only your own overtime');
    }
    if (session.status !== OvertimeSessionStatus.active || session.endedAt) {
      throw new ConflictException('Overtime session is already closed');
    }

    const geofence = await this.attendanceService.checkGeofence(
      actor.userId,
      data.lat,
      data.lng,
      data.accuracy,
    );
    if (!geofence.withinRange) {
      throw new ForbiddenException(
        `You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, outside the allowed range (${geofence.allowedRadiusMeters}m).`,
      );
    }

    const endedAt = serverNow();
    const actualMinutes = Math.floor(
      (endedAt.getTime() - session.startedAt.getTime()) / 60000,
    );
    if (actualMinutes < 1) {
      throw new ConflictException(
        'Overtime must run for at least one full minute before ending',
      );
    }

    const completed = await this.prisma.$transaction(async (tx) => {
      const closed = await tx.overtimeSession.updateMany({
        where: {
          id: sessionId,
          userId: actor.userId,
          status: OvertimeSessionStatus.active,
          endedAt: null,
        },
        data: {
          status: OvertimeSessionStatus.completed,
          endedAt,
          actualMinutes,
          endLocationLabel: geofence.nearestBranch,
          endLatitude: data.lat,
          endLongitude: data.lng,
          endGpsAccuracy: data.accuracy,
          endDistanceMeters: geofence.distanceMeters,
        },
      });
      if (closed.count !== 1) {
        throw new ConflictException('Overtime session was already closed');
      }

      await tx.overtimeRequest.update({
        where: { id: session.overtimeRequestId },
        data: { status: OvertimeStatus.completed },
      });

      return tx.overtimeSession.findUniqueOrThrow({ where: { id: sessionId } });
    });

    this.events.emitToUser(actor.userId, 'updated', {
      type: 'OvertimeSession',
      data: completed,
    });
    return completed;
  }

  private async findRequestForDecision(requestId: string) {
    const request = await this.prisma.overtimeRequest.findUnique({
      where: { id: requestId },
      include: { user: { select: { id: true, managerId: true } } },
    });
    if (!request) throw new NotFoundException('Overtime request not found');
    return request;
  }

  private async publishRequestUpdate(requestId: string) {
    const updated = await this.prisma.overtimeRequest.findUniqueOrThrow({
      where: { id: requestId },
      include: { session: true },
    });
    this.events.emitToUser(updated.userId, 'updated', {
      type: 'OvertimeRequest',
      data: updated,
    });
    return updated;
  }

  private assertHrApprover(role: string): void {
    if (!this.isHrApprover(role)) {
      throw new ForbiddenException('Only HR can take this decision');
    }
  }

  private isHrApprover(role: string): boolean {
    return [Role.hr, Role.hrAdmin, Role.superAdmin]
      .map((approverRole) => String(approverRole))
      .includes(role);
  }

  private isToday(value: Date, now: Date = serverNow()): boolean {
    return isSameEgyptAttendanceDay(value, now);
  }

  private normaliseComment(comment?: string): string | null {
    const normalised = comment?.trim();
    return normalised ? normalised : null;
  }

  private isUniqueConstraintError(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }
}
