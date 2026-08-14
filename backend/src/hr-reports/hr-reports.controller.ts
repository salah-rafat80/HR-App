import { Controller, Get, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '../auth/roles.enum';
import { RolesGuard } from '../auth/roles.guard';
import { MonthlyReportQueryDto } from './dto/monthly-report-query.dto';
import { HrReportsService } from './hr-reports.service';

@Controller('hr-reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.hr, Role.hrAdmin)
export class HrReportsController {
  constructor(private readonly reports: HrReportsService) {}

  @Get('monthly')
  getMonthly(@Query() query: MonthlyReportQueryDto): Promise<unknown> {
    return this.reports.getMonthlyReport(query);
  }

  @Get('monthly/export')
  async exportMonthly(
    @Query() query: MonthlyReportQueryDto,
    @Res() response: Response,
  ) {
    const file = await this.reports.exportMonthlyReport(query);
    const safeMonth = query.month.replace(/[^0-9-]/g, '');
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="hr-monthly-report-${safeMonth}.xlsx"`,
    );
    response.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    response.setHeader('Content-Length', file.length);
    response.send(file);
  }
}
