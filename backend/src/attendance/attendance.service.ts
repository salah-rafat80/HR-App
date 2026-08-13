import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AttendanceStatus, OfficeBranch } from '@prisma/client';
import { ClockInDto } from './dto/clock-in.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';

@Injectable()
export class AttendanceService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
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
      where: {
        userId,
        date: today,
      },
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

  private getDistanceFromLatLonInM(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) {
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

  private deg2rad(deg: number) {
    return deg * (Math.PI / 180);
  }

  async checkGeofence(lat: number, lng: number) {
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

      if (distance <= branch.radiusMeters) {
        withinRange = true;
      }
    }

    return {
      withinRange,
      distanceMeters: minDistance === Infinity ? 0 : minDistance,
      allowedRadiusMeters,
      nearestBranch: nearestBranch ? nearestBranch.name : 'Branch',
      branches: branches.map((b) => ({
        id: b.id,
        name: b.name,
        latitude: b.latitude,
        longitude: b.longitude,
        radiusMeters: b.radiusMeters,
      })),
    };
  }

  async clockIn(userId: string, data: ClockInDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let distanceMeters: number | undefined;

    if (data.lat !== undefined && data.lng !== undefined) {
      if (data.accuracy && data.accuracy > 100) {
        throw new ForbiddenException(
          `GPS accuracy too low (${data.accuracy}m). Please wait for a better signal.`,
        );
      }

      const geofence = await this.checkGeofence(data.lat, data.lng);
      if (!geofence.withinRange) {
        throw new ForbiddenException(
          `You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, outside the allowed range.`,
        );
      }
      distanceMeters = geofence.distanceMeters;
      data.locationLabel = geofence.nearestBranch || data.locationLabel;
    }

    let record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    const updateData = {
      clockInTime: new Date(),
      status: data.mode || AttendanceStatus.present,
      locationLabel: data.locationLabel || 'Main Office',
      clockInLat: data.lat,
      clockInLng: data.lng,
      distanceMeters: distanceMeters,
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
    return record;
  }

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
