import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { KpiService } from './kpi.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SubmitSelfAssessmentDto, AssignKpiDto } from './dto/kpi.dto';

@UseGuards(JwtAuthGuard)
@Controller('kpi')
export class KpiController {
  constructor(private readonly kpiService: KpiService) {}

  @Get('current')
  getCurrentKpis(@Request() req) {
    return this.kpiService.getCurrentKpis(req.user.userId);
  }

  @Get('history')
  getHistoricalScores(@Request() req) {
    return this.kpiService.getHistoricalScores(req.user.userId);
  }

  @Post(':id/self-assessment')
  submitSelfAssessment(
    @Request() req,
    @Param('id') id: string,
    @Body() data: SubmitSelfAssessmentDto,
  ) {
    return this.kpiService.submitSelfAssessment(req.user.userId, id, data.text);
  }

  @Post(':id/evidence')
  attachEvidence(@Request() req, @Param('id') id: string) {
    return this.kpiService.attachEvidence(req.user.userId, id);
  }

  @Get('overall-score')
  getOverallQuarterScore(@Request() req) {
    return this.kpiService.getOverallQuarterScore(req.user.userId);
  }

  @Get('team')
  getTeamKpis(@Request() req) {
    return this.kpiService.getTeamKpis(req.user.userId, req.user.role);
  }

  @Post('assign')
  assignKpi(@Request() req, @Body() data: AssignKpiDto) {
    return this.kpiService.assignKpi(req.user.userId, req.user.role, data);
  }
}
