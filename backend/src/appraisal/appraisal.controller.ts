import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AppraisalService } from './appraisal.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StartCycleDto, SubmitSelfAppraisalDto, SubmitPeerFeedbackDto } from './dto/appraisal.dto';

@UseGuards(JwtAuthGuard)
@Controller('appraisal')
export class AppraisalController {
  constructor(private readonly appraisalService: AppraisalService) {}

  @Get('cycle/current')
  getCurrentCycle(@Request() req) {
    return this.appraisalService.getCurrentCycle(req.user.userId);
  }

  @Get('self-appraisal/questions')
  getSelfAppraisalQuestions() {
    return this.appraisalService.getSelfAppraisalQuestions();
  }

  @Post('self-appraisal/submit')
  submitSelfAppraisal(@Request() req, @Body() data: SubmitSelfAppraisalDto) {
    return this.appraisalService.submitSelfAppraisal(req.user.userId, data.answers);
  }

  @Get('peer-feedback/peers')
  getPeersForFeedback(@Request() req) {
    return this.appraisalService.getPeersForFeedback(req.user.userId);
  }

  @Post('peer-feedback/submit')
  submitPeerFeedback(@Request() req, @Body() data: SubmitPeerFeedbackDto) {
    return this.appraisalService.submitPeerFeedback(req.user.userId, data.colleagueId, data.feedbackText);
  }

  @Get('results/my')
  getMyResults(@Request() req) {
    return this.appraisalService.getMyResults(req.user.userId);
  }

  @Get('development-plan')
  getDevelopmentPlan(@Request() req) {
    return this.appraisalService.getDevelopmentPlan(req.user.userId);
  }

  @Get('career-path')
  getCareerPath(@Request() req) {
    return this.appraisalService.getCareerPath(req.user.userId);
  }

  @Post('cycle/start')
  startNewCycle(@Request() req, @Body() data: StartCycleDto) {
    return this.appraisalService.startNewCycle(
      req.user.userId,
      req.user.role,
      data.label,
      new Date(data.dueDate),
    );
  }
}
