import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';
import { AttendanceStatus, OfficeBranch } from '@prisma/client';
import { ClockInDto } from './dto/clock-in.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';

/** Maximum accepted GPS accuracy in metres. */
const MAX_ACCURACY_METRES = 50;

export interface GeofenceResult {
  withinRange: boolean;
  distanceMeters: number;
  allowedRadiusMeters: number;
  nearestBranch: string;
}

export interface ClockInResponse {
  id: string;
  date: Date;
  clockInTime: Date | null;
  clockOutTime: Date | null;
  status: AttendanceStatus;
  locationLabel: string;
  distanceMeters: number | null;
}

@Injectable()
export class AttendanceService {
  private readonly logger = new Logger(AttendanceService.name);

  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
    private notifications: NotificationService,
  ) {}

  async getTodayStatus(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const activeLeaves = await this.prisma.leaveRequest.findMany({
      where: {
        userId,
        overallStatus: 'approved',
        startDate: { lte: new Date() },
        endDate: { gte: new Date(today) },
      },
    });

    if (activeLeaves.length > 0) {
      return {
        date: new Date(),
        status: AttendanceStatus.onLeave,
        locationLabel: 'none',
      };
    }

    const record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (record) {
      return record;
    }

    return {
      date: new Date(),
      status: AttendanceStatus.none,
      locationLabel: 'none',
    };
  }

  // ── Haversine ──────────────────────────────────────────────────────────────

  private getDistanceFromLatLonInM(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371000;
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  // ── Shared coordinate validation ───────────────────────────────────────────

  private assertCoordinatesValid(
    lat: number,
    lng: number,
    accuracy: number,
  ): void {
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new BadRequestException('lat and lng must be finite numbers');
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw new BadRequestException('lat or lng out of valid geographic range');
    }
    if (!Number.isFinite(accuracy) || accuracy <= 0) {
      throw new BadRequestException('accuracy must be a positive finite number');
    }
    if (accuracy > MAX_ACCURACY_METRES) {
      throw new BadRequestException(
        `GPS accuracy too low (${accuracy}m). Must be ≤ ${MAX_ACCURACY_METRES}m.`,
      );
    }
  }

  // ── Single geofence computation used by BOTH preflight and clock-in ────────

  /**
   * Returns the geofence result for the given position.
   * Conservative rule: distanceMeters + accuracyMeters <= branch.radiusMeters
   * Both preflight (GET) and clock-in (POST) call this method.
   */
  async checkGeofence(
    lat: number,
    lng: number,
    accuracy: number,
  ): Promise<GeofenceResult> {
    this.assertCoordinatesValid(lat, lng, accuracy);

    const branches: OfficeBranch[] = await this.prisma.officeBranch.findMany({
      where: { isActive: true },
    });

    let nearestBranch: OfficeBranch | null = null;
    let minDistance = Infinity;
    let withinRange = false;
    let allowedRadiusMeters = 200;

    for (const branch of branches) {
      const distance = this.getDistanceFromLatLonInM(
        lat,
        lng,
        branch.latitude,
        branch.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestBranch = branch;
        allowedRadiusMeters = branch.radiusMeters;
      }

      // Conservative rule: distance + accuracy uncertainty must fit within radius
      if (distance + accuracy <= branch.radiusMeters) {
        withinRange = true;
      }
    }

    return {
      withinRange,
      distanceMeters: minDistance === Infinity ? 0 : minDistance,
      allowedRadiusMeters,
      nearestBranch: nearestBranch ? nearestBranch.name : 'Branch',
    };
  }

  // ── Clock In ───────────────────────────────────────────────────────────────

  async clockIn(
    userId: string,
    data: ClockInDto,
  ): Promise<ClockInResponse> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Server independently revalidates geofence before any DB write.
    const geofence = await this.checkGeofence(data.lat, data.lng, data.accuracy);
    if (!geofence.withinRange) {
      throw new ForbiddenException(
        `You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, ` +
          `outside the allowed range (${geofence.allowedRadiusMeters}m).`,
      );
    }

    // Branch label is derived from the server's geofence result — never from client.
    const locationLabel = geofence.nearestBranch;

    let record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    const updateData = {
      clockInTime: new Date(),
      status: data.mode || AttendanceStatus.present,
      locationLabel,
      clockInLat: data.lat,
      clockInLng: data.lng,
      distanceMeters: geofence.distanceMeters,
    };

    if (record) {
      record = await this.prisma.attendanceRecord.update({
        where: { id: record.id },
        data: updateData,
      });
    } else {
      record = await this.prisma.attendanceRecord.create({
        data: {
          userId,
          date: today,
          ...updateData,
        },
      });
    }

    // WebSocket is an additional UI refresh — not the source of truth.
    this.events.emitToUser(userId, 'updated', {
      type: 'AttendanceRecord',
      data: record,
    });

    // Non-blocking FCM attempt after successful DB commit.
    // FCM failure never rolls back the persisted record.
    void this.sendAttendanceFcm(userId, record.id, record.clockInTime!);

    // Return the persisted record as the authoritative response.
    return {
      id: record.id,
      date: record.date,
      clockInTime: record.clockInTime,
      clockOutTime: record.clockOutTime,
      status: record.status,
      locationLabel: record.locationLabel,
      distanceMeters: record.distanceMeters,
    };
  }

  private async sendAttendanceFcm(
    userId: string,
    recordId: string,
    clockInTime: Date,
  ): Promise<void> {
    try {
      // Minimal select — never log full token.
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      if (!user?.fcmToken) return;

      const timeStr = clockInTime.toLocaleTimeString('ar-EG', {
        hour: '2-digit',
        minute: '2-digit',
      });

      await this.notifications.sendToDevice({
        token: user.fcmToken,
        title: '✅ تم تسجيل حضورك',
        body: `تم تسجيل حضورك اليوم الساعة ${timeStr}`,
        data: { type: 'attendance_clock_in', id: recordId },
      });
    } catch (err) {
      // Log without exposing token or sensitive data.
      this.logger.error(
        `FCM attendance notification failed for userId=${userId}: ${String(err)}`,
      );
    }
  }

  // ── Clock Out ──────────────────────────────────────────────────────────────

  async clockOut(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const now = new Date();

    const record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (!record) {
      throw new NotFoundException('No clock-in record found for today');
    }

    const updated = await this.prisma.attendanceRecord.update({
      where: { id: record.id },
      data: { clockOutTime: now },
    });

    this.events.emitToUser(userId, 'updated', {
      type: 'AttendanceRecord',
      data: updated,
    });
    return updated;
  }

  async getHistory(userId: string) {
    return this.prisma.attendanceRecord.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 30,
    });
  }

  async getShift(userId: string) {
    return this.prisma.shiftInfo.findFirst({
      where: { userId },
    });
  }

  async requestOvertime(userId: string, data: RequestOvertimeDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.prisma.overtimeRequest.create({
      data: {
        userId,
        date: today,
        hoursRequested: data.hoursRequested,
        reason: data.reason,
        status: 'pending',
      },
    });
  }

  startBreak(userId: string) {
    return { status: 'Break started', userId };
  }

  endBreak(userId: string) {
    return { status: 'Break ended', userId };
  }
}
