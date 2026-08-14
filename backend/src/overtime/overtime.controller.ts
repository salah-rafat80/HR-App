import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';
import { RolesGuard } from '../auth/roles.guard';
import { OvertimeDecisionDto } from './dto/decision.dto';
import { OvertimeLocationDto } from './dto/overtime-location.dto';
import { RequestOvertimeDto } from './dto/request-overtime.dto';
import { OvertimeService } from './overtime.service';

interface AuthenticatedRequest extends Request {
  user: {
    userId: string;
    role: string;
  };
}

@Controller('overtime')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OvertimeController {
  constructor(private readonly overtimeService: OvertimeService) {}

  @Post('requests')
  requestOvertime(
    @Req() req: AuthenticatedRequest,
    @Body() data: RequestOvertimeDto,
  ) {
    return this.overtimeService.requestOvertime(req.user, data);
  }

  @Get('requests/mine')
  getMyRequests(@Req() req: AuthenticatedRequest) {
    return this.overtimeService.getMyRequests(req.user.userId);
  }

  @Get('approvals/pending')
  @Roles(Role.team_lead, Role.hr, Role.hrAdmin)
  getPendingApprovals(@Req() req: AuthenticatedRequest) {
    return this.overtimeService.getPendingApprovals(req.user);
  }

  @Post('requests/:id/team-lead/approve')
  @Roles(Role.team_lead)
  approveAsTeamLead(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeDecisionDto,
  ) {
    return this.overtimeService.approveAsTeamLead(id, req.user, data);
  }

  @Post('requests/:id/team-lead/reject')
  @Roles(Role.team_lead)
  rejectAsTeamLead(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeDecisionDto,
  ) {
    return this.overtimeService.rejectAsTeamLead(id, req.user, data);
  }

  @Post('requests/:id/hr/approve')
  @Roles(Role.hr, Role.hrAdmin)
  approveAsHr(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeDecisionDto,
  ) {
    return this.overtimeService.approveAsHr(id, req.user, data);
  }

  @Post('requests/:id/hr/reject')
  @Roles(Role.hr, Role.hrAdmin)
  rejectAsHr(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeDecisionDto,
  ) {
    return this.overtimeService.rejectAsHr(id, req.user, data);
  }

  @Post('requests/:id/session/start')
  startSession(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeLocationDto,
  ) {
    return this.overtimeService.startSession(id, req.user, data);
  }

  @Post('sessions/:id/end')
  endSession(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() data: OvertimeLocationDto,
  ) {
    return this.overtimeService.endSession(id, req.user, data);
  }
}
