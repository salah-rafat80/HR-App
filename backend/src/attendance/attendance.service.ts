import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { NotificationService } from '../notifications/notification.service';
import { AttendanceStatus } from '@prisma/client';
import { ClockInDto } from './dto/clock-in.dto';
import {
  formatEgyptTime,
  serverNow,
  startOfEgyptAttendanceDay,
} from '../common/time/egypt-time.util';

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
    const now = serverNow();
    const today = startOfEgyptAttendanceDay(now);

    const activeLeaves = await this.prisma.leaveRequest.findMany({
      where: {
        userId,
        overallStatus: 'approved',
        startDate: { lte: today },
        endDate: { gte: today },
      },
    });

    if (activeLeaves.length > 0) {
      return {
        date: today,
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
      date: today,
      status: AttendanceStatus.none,
      locationLabel: 'none',
    };
  }

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
      throw new BadRequestException(
        'accuracy must be a positive finite number',
      );
    }
    if (accuracy > MAX_ACCURACY_METRES) {
      throw new BadRequestException(
        `GPS accuracy too low (${accuracy}m). Must be ≤ ${MAX_ACCURACY_METRES}m.`,
      );
    }
  }

  /**
   * Checks whether the given GPS coordinates are within the employee's
   * assigned office branch radius. Only the actor's assigned branch is
   * consulted — other active branches are never used for authorisation.
   */
  async checkGeofence(
    userId: string,
    lat: number,
    lng: number,
    accuracy: number,
  ): Promise<GeofenceResult> {
    this.assertCoordinatesValid(lat, lng, accuracy);

    const employee = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { branch: true },
    });
    if (!employee) throw new NotFoundException('Employee not found');
    if (!employee.branchId || !employee.branch) {
      throw new ForbiddenException(
        'No office branch is assigned to this employee',
      );
    }
    if (!employee.branch.isActive) {
      throw new ForbiddenException('The assigned office branch is inactive');
    }

    const distanceMeters = this.getDistanceFromLatLonInM(
      lat,
      lng,
      employee.branch.latitude,
      employee.branch.longitude,
    );
    return {
      withinRange: distanceMeters + accuracy <= employee.branch.radiusMeters,
      distanceMeters,
      allowedRadiusMeters: employee.branch.radiusMeters,
      nearestBranch: employee.branch.name,
    };
  }

  async clockIn(userId: string, data: ClockInDto): Promise<ClockInResponse> {
    const now = serverNow();
    const today = startOfEgyptAttendanceDay(now);

    let record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (record) {
      if (record.clockOutTime !== null) {
        throw new ConflictException('Today attendance is closed');
      }
      if (record.clockInTime !== null) {
        throw new ConflictException('Employee is already clocked in today');
      }
    }

    const geofence = await this.checkGeofence(
      userId,
      data.lat,
      data.lng,
      data.accuracy,
    );
    if (!geofence.withinRange) {
      throw new ForbiddenException(
        `You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, ` +
          `outside the allowed range (${geofence.allowedRadiusMeters}m).`,
      );
    }

    const locationLabel = geofence.nearestBranch;

    const updateData = {
      clockInTime: now,
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

    this.events.emitToUser(userId, 'updated', {
      type: 'AttendanceRecord',
      data: record,
    });

    void this.sendAttendanceFcm(userId, record.id, record.clockInTime!);

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
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      if (!user?.fcmToken) return;

      const timeStr = formatEgyptTime(clockInTime);

      await this.notifications.sendToDevice({
        token: user.fcmToken,
        title: '✅ تم تسجيل حضورك',
        body: `تم تسجيل حضورك اليوم الساعة ${timeStr}`,
        data: { type: 'attendance_clock_in', id: recordId },
      });
    } catch (err) {
      this.logger.error(
        `FCM attendance notification failed for userId=${userId}: ${String(err)}`,
      );
    }
  }

  async clockOut(userId: string) {
    const now = serverNow();
    const today = startOfEgyptAttendanceDay(now);

    const record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (!record) {
      throw new NotFoundException('No clock-in record found for today');
    }

    if (record.clockInTime === null) {
      throw new ConflictException('No active clock-in exists today');
    }

    if (record.clockOutTime !== null) {
      throw new ConflictException('Employee is already clocked out today');
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

  startBreak(userId: string) {
    return { status: 'Break started', userId };
  }

  endBreak(userId: string) {
    return { status: 'Break ended', userId };
  }
}
