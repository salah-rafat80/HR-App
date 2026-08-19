/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment */
import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Delete,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { LeaveService } from './leave.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';
import {
  CreateLeaveRequestDto,
  LeaveType,
} from './dto/create-leave-request.dto';
import { CreateLeavePolicyDto } from './dto/create-leave-policy.dto';
import { UpdateLeavePolicyDto } from './dto/update-leave-policy.dto';
import { CreateLeaveBalanceDto } from './dto/create-leave-balance.dto';
import { AdjustLeaveBalanceDto } from './dto/adjust-leave-balance.dto';
import { ApprovalActionDto } from './dto/approval-action.dto';
import { CancelLeaveRequestDto } from './dto/cancel-leave-request.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('leave')
export class LeaveController {
  constructor(private readonly leaveService: LeaveService) {}

  // ==========================================
  // Leave Policies (HR / Authenticated)
  // ==========================================

  @Get('policies')
  getPolicies(@Request() req) {
    const isHr = ['hr', 'hrAdmin', 'superAdmin'].includes(req.user.role);
    return this.leaveService.getPolicies(isHr);
  }

  @Post('policies')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  createPolicy(@Request() req, @Body() data: CreateLeavePolicyDto) {
    return this.leaveService.createPolicy(req.user.userId, data);
  }

  @Patch('policies/:type')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  updatePolicy(
    @Request() req,
    @Param('type') type: LeaveType,
    @Body() data: UpdateLeavePolicyDto,
  ) {
    return this.leaveService.updatePolicy(req.user.userId, type, data);
  }

  @Post('policies/:type/toggle')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  togglePolicy(@Request() req, @Param('type') type: LeaveType) {
    return this.leaveService.togglePolicy(req.user.userId, type);
  }

  // ==========================================
  // Leave Balances (HR / Employee)
  // ==========================================

  @Get('balances')
  getBalances(@Request() req) {
    return this.leaveService.getBalances(req.user.userId);
  }

  @Get('balances/admin')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  getBalancesAdmin(
    @Query('page') page: string,
    @Query('limit') limit: string,
    @Query('employeeId') employeeId?: string,
    @Query('department') department?: string,
    @Query('branchId') branchId?: string,
    @Query('year') year?: string,
  ) {
    return this.leaveService.getBalancesAdmin(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 10,
      employeeId,
      department,
      branchId,
      year ? parseInt(year, 10) : undefined,
    );
  }

  @Post('balances')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  createBalance(@Request() req, @Body() data: CreateLeaveBalanceDto) {
    return this.leaveService.createBalance(req.user.userId, data);
  }

  @Post('balances/:id/adjust')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  adjustBalance(
    @Request() req,
    @Param('id') id: string,
    @Body() data: AdjustLeaveBalanceDto,
  ) {
    return this.leaveService.adjustBalance(req.user.userId, id, data);
  }

  // ==========================================
  // Company Configuration
  // ==========================================

  @Get('config')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  getCompanyApprovalConfig() {
    return this.leaveService.getCompanyApprovalConfig();
  }

  @Post('config')
  @Roles(Role.hr, Role.hrAdmin, Role.superAdmin)
  updateCompanyApprovalConfig(
    @Request() req,
    @Body('finalHrApproverId') finalHrApproverId: string | null,
  ) {
    return this.leaveService.updateCompanyApprovalConfig(
      req.user.userId,
      finalHrApproverId,
    );
  }

  // ==========================================
  // Employee Leave Requests & Actions
  // ==========================================

  @Get('my-requests')
  getMyRequests(@Request() req) {
    return this.leaveService.getMyRequests(req.user.userId);
  }

  @Post('preview')
  previewLeave(@Request() req, @Body() data: CreateLeaveRequestDto) {
    return this.leaveService.previewLeave(req.user.userId, data);
  }

  @Post('apply')
  applyLeave(@Request() req, @Body() data: CreateLeaveRequestDto) {
    return this.leaveService.applyLeave(req.user.userId, data);
  }

  @Post(':id/cancel')
  cancelRequest(
    @Request() req,
    @Param('id') id: string,
    @Body() data: CancelLeaveRequestDto,
  ) {
    return this.leaveService.cancelRequest(id, req.user.userId, data);
  }

  @Delete(':id')
  legacyCancelRequest(@Request() req, @Param('id') id: string) {
    return this.leaveService.cancelRequest(id, req.user.userId, {
      reason: 'Cancelled via legacy DELETE method',
    });
  }

  @Get('team-calendar')
  getTeamCalendar() {
    return this.leaveService.getTeamCalendar();
  }

  // ==========================================
  // Approval Actions & Queues
  // ==========================================

  @Get('pending')
  getPendingApprovals(
    @Request() req,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.leaveService.getPendingApprovals(
      req.user.role,
      req.user.userId,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 10,
    );
  }

  @Post(':id/approve')
  approveRequest(
    @Request() req,
    @Param('id') id: string,
    @Body() data: ApprovalActionDto,
  ) {
    return this.leaveService.approveRequest(
      id,
      req.user.userId,
      req.user.role,
      data,
    );
  }

  @Post(':id/reject')
  rejectRequest(
    @Request() req,
    @Param('id') id: string,
    @Body() data: ApprovalActionDto,
  ) {
    return this.leaveService.rejectRequest(
      id,
      req.user.userId,
      req.user.role,
      data,
    );
  }
}
