import { Controller, Get, Post, Body, Param, Delete, UseGuards, Request } from '@nestjs/common';
import { LeaveService } from './leave.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateLeaveRequestDto } from './dto/create-leave-request.dto';

@UseGuards(JwtAuthGuard)
@Controller('leave')
export class LeaveController {
  constructor(private readonly leaveService: LeaveService) {}

  @Get('balances')
  getBalances(@Request() req) {
    return this.leaveService.getBalances(req.user.userId);
  }

  @Get('my-requests')
  getMyRequests(@Request() req) {
    return this.leaveService.getMyRequests(req.user.userId);
  }

  @Post('apply')
  applyLeave(@Request() req, @Body() data: CreateLeaveRequestDto) {
    return this.leaveService.applyLeave(req.user.userId, data);
  }

  @Delete(':id')
  cancelRequest(@Param('id') id: string) {
    return this.leaveService.cancelRequest(id);
  }

  @Get('team-calendar')
  getTeamCalendar() {
    return this.leaveService.getTeamCalendar();
  }

  @Get('pending')
  getPendingApprovals() {
    return this.leaveService.getPendingApprovals();
  }

  @Post(':id/approve')
  approveRequest(@Param('id') id: string) {
    return this.leaveService.approveRequest(id);
  }

  @Post(':id/reject')
  rejectRequest(@Param('id') id: string) {
    return this.leaveService.rejectRequest(id);
  }
}
