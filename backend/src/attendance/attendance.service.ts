import { Injectable, InternalServerErrorException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AttendanceStatus, OfficeBranch } from '@prisma/client';
import { ClockInDto } from './dto/clock-in.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';

@Injectable()
export class AttendanceService {
  private inMemoryRecords: Map<string, any> = new Map();

  private fallbackBranches: OfficeBranch[] = [
    {
      id: 'branch_main',
      name: 'Main Office',
      latitude: 30.286884,
      longitude: 31.756905,
      radiusMeters: 200,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  async getTodayStatus(userId: string) {
    try {
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

      let record = await this.prisma.attendanceRecord.findFirst({
        where: {
          userId,
          date: today,
        },
      });

      if (record) {
        return record;
      }
    } catch (e) {
      console.warn('Database offline, checking in-memory attendance records');
    }

    const inMem = this.inMemoryRecords.get(userId);
    if (inMem) {
      return inMem;
    }

    return {
      date: new Date(),
      status: AttendanceStatus.none,
      locationLabel: 'none',
    };
  }

  private getDistanceFromLatLonInM(lat1: number, lon1: number, lat2: number, lon2: number) {
    const R = 6371000; // Radius of the earth in m
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in m
  }

  private deg2rad(deg: number) {
    return deg * (Math.PI / 180);
  }

  async checkGeofence(lat: number, lng: number) {
    let branches: OfficeBranch[] = [];
    try {
      branches = await this.prisma.officeBranch.findMany({
        where: { isActive: true },
      });
    } catch (e) {
      console.warn('Database offline, using fallback branches for geofence');
      branches = this.fallbackBranches;
    }

    if (branches.length === 0) {
      branches = this.fallbackBranches;
    }

    let nearestBranch: OfficeBranch | null = null;
    let minDistance = Infinity;
    let withinRange = false;
    let allowedRadiusMeters = 200;

    for (const branch of branches) {
      const distance = this.getDistanceFromLatLonInM(lat, lng, branch.latitude, branch.longitude);
      
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
      distanceMeters: minDistance,
      allowedRadiusMeters,
      nearestBranch: nearestBranch ? nearestBranch.name : 'Main Office',
      branches: branches.map(b => ({
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
    
    // GPS validation if coords provided
    if (data.lat !== undefined && data.lng !== undefined) {
      if (data.accuracy && data.accuracy > 100) {
        throw new ForbiddenException(`GPS accuracy too low (${data.accuracy}m). Please wait for a better signal.`);
      }
      
      const geofence = await this.checkGeofence(data.lat, data.lng);
      if (!geofence.withinRange) {
        throw new ForbiddenException(`You are ${Math.round(geofence.distanceMeters)}m from ${geofence.nearestBranch}, outside the allowed range.`);
      }
      distanceMeters = geofence.distanceMeters;
      data.locationLabel = geofence.nearestBranch || data.locationLabel;
    }

    const clockInRecord = {
      id: `att_${Date.now()}`,
      userId,
      date: today,
      clockInTime: new Date(),
      clockOutTime: null,
      status: data.mode || AttendanceStatus.present,
      locationLabel: data.locationLabel || 'Main Office',
      clockInLat: data.lat,
      clockInLng: data.lng,
      distanceMeters: distanceMeters,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    try {
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

      this.inMemoryRecords.set(userId, record);
      this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: record });
      return record;
    } catch (e) {
      console.warn('Database offline, saving clock-in record in-memory');
      this.inMemoryRecords.set(userId, clockInRecord);
      this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: clockInRecord });
      return clockInRecord;
    }
  }

  async clockOut(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const now = new Date();

    try {
      const record = await this.prisma.attendanceRecord.findFirst({
        where: { userId, date: today },
      });

      if (record) {
        const updated = await this.prisma.attendanceRecord.update({
          where: { id: record.id },
          data: { clockOutTime: now },
        });
        this.inMemoryRecords.set(userId, updated);
        this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: updated });
        return updated;
      }
    } catch (e) {
      console.warn('Database offline, updating clock-out record in-memory');
    }

    let existing = this.inMemoryRecords.get(userId);
    if (existing) {
      existing = { ...existing, clockOutTime: now, updatedAt: now };
      this.inMemoryRecords.set(userId, existing);
      this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: existing });
      return existing;
    }

    const clockOutRecord = {
      id: `att_${Date.now()}`,
      userId,
      date: today,
      clockInTime: now,
      clockOutTime: now,
      status: AttendanceStatus.present,
      locationLabel: 'Main Office',
      createdAt: now,
      updatedAt: now,
    };
    this.inMemoryRecords.set(userId, clockOutRecord);
    return clockOutRecord;
  }

  async getHistory(userId: string) {
    try {
      return await this.prisma.attendanceRecord.findMany({
        where: { userId },
        orderBy: { date: 'desc' },
        take: 30, // Last 30 days
      });
    } catch (e) {
      console.warn('Database offline, returning fallback empty history');
      return [];
    }
  }

  async getShift(userId: string) {
    try {
      let shift = await this.prisma.shiftInfo.findFirst({
        where: { userId },
      });
      if (shift) return shift;
    } catch (e) {
      console.warn('Database offline, returning default shift info');
    }

    const today = new Date();
    const startTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 9, 0, 0);
    const endTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 17, 0, 0);
    
    return {
      id: 'default',
      userId,
      shiftName: 'Default Morning Shift',
      startTime,
      endTime,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
  }

  async requestOvertime(userId: string, data: RequestOvertimeDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      const req = await this.prisma.overtimeRequest.create({
        data: {
          userId,
          date: today,
          hoursRequested: data.hoursRequested,
          reason: data.reason,
          status: 'pending',
        },
      });
      return req;
    } catch (e) {
      return { status: 'pending', hoursRequested: data.hoursRequested, reason: data.reason };
    }
  }

  async startBreak(userId: string) {
    return { status: 'Break started' };
  }

  async endBreak(userId: string) {
    return { status: 'Break ended' };
  }
}

