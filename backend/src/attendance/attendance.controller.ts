import {
  Controller,
  Get,
  Post,
  Body,
  Req,
  Query,
  UseGuards,
  BadRequestException,
  ParseFloatPipe,
} from '@nestjs/common';
import { Request } from 'express';
import { AttendanceService } from './attendance.service';
import { ClockInDto } from './dto/clock-in.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

interface AuthenticatedRequest extends Request {
  user: {
    userId: string;
  };
}

@Controller('attendance')
@UseGuards(JwtAuthGuard)
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Get('today')
  getTodayStatus(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.getTodayStatus(req.user.userId);
  }

  @Get('geofence-status')
  async getGeofenceStatus(
    @Req() req: AuthenticatedRequest,
    @Query('lat', ParseFloatPipe) lat: number,
    @Query('lng', ParseFloatPipe) lng: number,
    @Query('accuracy', ParseFloatPipe) accuracy: number,
  ) {
    if (
      !Number.isFinite(lat) ||
      !Number.isFinite(lng) ||
      !Number.isFinite(accuracy)
    ) {
      throw new BadRequestException(
        'lat, lng, and accuracy must be finite numbers',
      );
    }
    return this.attendanceService.checkGeofence(
      req.user.userId,
      lat,
      lng,
      accuracy,
    );
  }

  @Post('clock-in')
  clockIn(@Req() req: AuthenticatedRequest, @Body() data: ClockInDto) {
    return this.attendanceService.clockIn(req.user.userId, data);
  }

  @Post('clock-out')
  clockOut(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.clockOut(req.user.userId);
  }

  @Get('history')
  getHistory(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.getHistory(req.user.userId);
  }

  @Get('shift')
  getShift(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.getShift(req.user.userId);
  }

  @Post('break/start')
  startBreak(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.startBreak(req.user.userId);
  }

  @Post('break/end')
  endBreak(@Req() req: AuthenticatedRequest) {
    return this.attendanceService.endBreak(req.user.userId);
  }
}
