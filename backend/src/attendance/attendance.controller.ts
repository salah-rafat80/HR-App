import { Controller, Get, Post, Body, Req, UseGuards, BadRequestException } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { ClockInDto } from './dto/clock-in.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('attendance')
@UseGuards(JwtAuthGuard)
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Get('today')
  getTodayStatus(@Req() req) {
    return this.attendanceService.getTodayStatus(req.user.userId);
  }

  @Get('geofence-status')
  async getGeofenceStatus(@Req() req) {
    const lat = parseFloat(req.query.lat as string);
    const lng = parseFloat(req.query.lng as string);
    if (isNaN(lat) || isNaN(lng)) {
      throw new BadRequestException('Invalid coordinates');
    }
    return this.attendanceService.checkGeofence(lat, lng);
  }

  @Post('clock-in')
  clockIn(@Req() req, @Body() data: ClockInDto) {
    return this.attendanceService.clockIn(req.user.userId, data);
  }

  @Post('clock-out')
  clockOut(@Req() req) {
    return this.attendanceService.clockOut(req.user.userId);
  }

  @Get('history')
  getHistory(@Req() req) {
    return this.attendanceService.getHistory(req.user.userId);
  }

  @Get('shift')
  getShift(@Req() req) {
    return this.attendanceService.getShift(req.user.userId);
  }

  @Post('overtime')
  requestOvertime(@Req() req, @Body() data: RequestOvertimeDto) {
    return this.attendanceService.requestOvertime(req.user.userId, data);
  }

  @Post('break/start')
  startBreak(@Req() req) {
    return this.attendanceService.startBreak(req.user.userId);
  }

  @Post('break/end')
  endBreak(@Req() req) {
    return this.attendanceService.endBreak(req.user.userId);
  }
}
