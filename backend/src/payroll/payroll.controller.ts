import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { CreatePayrollRunDto } from './dto/payroll.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';

@UseGuards(JwtAuthGuard)
@Controller('payroll')
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  // Employee-facing endpoints
  @Get('payslips')
  async getPayslips(@Request() req) {
    return this.payrollService.getPayslips(req.user.userId);
  }

  @Get('payslips/:monthLabel')
  async getPayslipDetail(
    @Request() req,
    @Param('monthLabel') monthLabel: string,
  ) {
    return this.payrollService.getPayslipDetail(req.user.userId, monthLabel);
  }

  @Get('ytd')
  async getYtdSummary(@Request() req) {
    return this.payrollService.getYtdSummary(req.user.userId);
  }

  @Get('bonus-notice')
  async getCurrentBonusNotice(@Request() req) {
    return this.payrollService.getCurrentBonusNotice(req.user.userId);
  }

  @Post('tax-certificate/download')
  @HttpCode(HttpStatus.OK)
  async downloadTaxCertificate() {
    return {
      success: true,
      message: 'Tax certificate downloaded successfully',
    };
  }

  // Admin-facing endpoints
  @Get('runs')
  @UseGuards(RolesGuard)
  @Roles(Role.hrAdmin, Role.superAdmin, Role.hr)
  async getPayrollRuns() {
    return this.payrollService.getPayrollRuns();
  }

  @Post('runs')
  @UseGuards(RolesGuard)
  @Roles(Role.hrAdmin, Role.superAdmin)
  async createRun(@Body() data: CreatePayrollRunDto) {
    return this.payrollService.createRun(data.periodLabel);
  }

  @Post('runs/:id/process')
  @UseGuards(RolesGuard)
  @Roles(Role.hrAdmin, Role.superAdmin)
  async processRun(@Param('id') id: string) {
    return this.payrollService.processRun(id);
  }

  @Post('runs/:id/approve')
  @UseGuards(RolesGuard)
  @Roles(Role.hrAdmin, Role.superAdmin)
  async approveRun(@Param('id') id: string) {
    return this.payrollService.approveRun(id);
  }
}
