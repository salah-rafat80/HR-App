import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AttendanceStatus } from '@prisma/client';
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

    // 1. Check Leave Sync (Real Logic)
    const activeLeaves = await this.prisma.leaveRequest.findMany({
      where: {
        userId,
        overallStatus: 'approved',
        startDate: { lte: new Date() },
        endDate: { gte: new Date(today) }, // gte the start of today
      },
    });

    if (activeLeaves.length > 0) {
      return {
        date: new Date(),
        status: AttendanceStatus.onLeave,
        locationLabel: 'none',
      };
    }

    // 2. Return real attendance record for today if exists
    let record = await this.prisma.attendanceRecord.findFirst({
      where: {
        userId,
        date: today,
      },
    });

    if (!record) {
      return {
        date: new Date(),
        status: AttendanceStatus.none,
        locationLabel: 'none',
      };
    }

    return record;
  }

  async clockIn(userId: string, data: ClockInDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (record) {
      record = await this.prisma.attendanceRecord.update({
        where: { id: record.id },
        data: {
          clockInTime: new Date(),
          status: data.mode,
          locationLabel: data.locationLabel,
        },
      });
    } else {
      record = await this.prisma.attendanceRecord.create({
        data: {
          userId,
          date: today,
          clockInTime: new Date(),
          status: data.mode,
          locationLabel: data.locationLabel,
        },
      });
    }

    // Emit live event
    this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: record });
    return record;
  }

  async clockOut(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const record = await this.prisma.attendanceRecord.findFirst({
      where: { userId, date: today },
    });

    if (record) {
      const updated = await this.prisma.attendanceRecord.update({
        where: { id: record.id },
        data: { clockOutTime: new Date() },
      });
      this.events.emitToUser(userId, 'updated', { type: 'AttendanceRecord', data: updated });
      return updated;
    }
  }

  async getHistory(userId: string) {
    return this.prisma.attendanceRecord.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 30, // Last 30 days
    });
  }

  async getShift(userId: string) {
    let shift = await this.prisma.shiftInfo.findFirst({
      where: { userId },
    });

    if (!shift) {
      // Return a default shift if none assigned
      const today = new Date();
      const startTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 9, 0, 0);
      const endTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 17, 0, 0);
      
      shift = {
        id: 'default',
        userId,
        shiftName: 'Default Morning Shift',
        startTime,
        endTime,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
    }
    return shift;
  }

  async requestOvertime(userId: string, data: RequestOvertimeDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const req = await this.prisma.overtimeRequest.create({
      data: {
        userId,
        date: today,
        hoursRequested: data.hoursRequested,
        reason: data.reason,
        status: 'pending',
      },
    });
    
    // Optionally emit to manager here
    return req;
  }

  async startBreak(userId: string) {
    // Basic stub - not tracked in DB schema currently as per instructions
    return { status: 'Break started' };
  }

  async endBreak(userId: string) {
    return { status: 'Break ended' };
  }
}
