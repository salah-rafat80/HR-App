import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AssignKpiDto } from './dto/kpi.dto';

@Injectable()
export class KpiService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  async getCurrentKpis(userId: string) {
    return this.prisma.kpi.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getHistoricalScores(userId: string) {
    return this.prisma.kpiQuarterScore.findMany({
      where: { userId },
      orderBy: { quarterLabel: 'desc' },
    });
  }

  async submitSelfAssessment(userId: string, kpiId: string, text: string) {
    const kpi = await this.prisma.kpi.findUnique({ where: { id: kpiId } });
    if (!kpi) throw new NotFoundException('KPI not found');
    if (kpi.userId !== userId) {
      throw new ForbiddenException(
        'You can only submit self-assessment for your own KPIs',
      );
    }

    // Bump current value by 5% of target as a demo touch
    let newCurrent = kpi.currentValue + kpi.targetValue * 0.05;
    if (newCurrent > kpi.targetValue) newCurrent = kpi.targetValue;

    const updated = await this.prisma.kpi.update({
      where: { id: kpiId },
      data: {
        selfAssessmentText: text,
        currentValue: newCurrent,
      },
    });

    // Notify via WebSockets
    this.events.emitEntityUpdated('Kpi', 'updated', updated);

    return updated;
  }

  async attachEvidence(userId: string, kpiId: string) {
    const kpi = await this.prisma.kpi.findUnique({ where: { id: kpiId } });
    if (!kpi) throw new NotFoundException('KPI not found');
    if (kpi.userId !== userId) {
      throw new ForbiddenException(
        'You can only attach evidence to your own KPIs',
      );
    }

    const updated = await this.prisma.kpi.update({
      where: { id: kpiId },
      data: { hasEvidence: true },
    });

    this.events.emitEntityUpdated('Kpi', 'updated', updated);

    return updated;
  }

  async getOverallQuarterScore(userId: string) {
    const kpis = await this.prisma.kpi.findMany({ where: { userId } });
    if (kpis.length === 0) return { overallScore: 0.0 };

    const totalProgress = kpis.reduce((sum, kpi) => {
      const p = kpi.targetValue > 0 ? kpi.currentValue / kpi.targetValue : 0;
      return sum + (p > 1.0 ? 1.0 : p);
    }, 0);

    return { overallScore: totalProgress / kpis.length };
  }

  async getManagedUserIds(actorUserId: string): Promise<string[]> {
    const directReports = await this.prisma.user.findMany({
      where: { managerId: actorUserId },
      select: { id: true },
    });
    const ids = directReports.map((u) => u.id);
    const childPromises = ids.map((id) => this.getManagedUserIds(id));
    const childIdsList = await Promise.all(childPromises);
    return ids.concat(...childIdsList);
  }

  async getLeaveStatus(userId: string, today: Date): Promise<string> {
    const activeLeave = await this.prisma.leaveRequest.findFirst({
      where: {
        userId,
        overallStatus: 'approved',
        startDate: { lte: today },
        endDate: { gte: today },
      },
    });
    if (activeLeave) return 'onLeave';

    const startOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    const endOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
      23,
      59,
      59,
    );

    const wfhRecord = await this.prisma.attendanceRecord.findFirst({
      where: {
        userId,
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
        status: 'workFromHome',
      },
    });
    if (wfhRecord) return 'wfh';

    return 'present';
  }

  async getTeamKpis(actorUserId: string, actorRole: string) {
    const whereCondition =
      actorRole === 'hr' || actorRole === 'hrAdmin'
        ? { role: 'employee' }
        : {
            id: { in: await this.getManagedUserIds(actorUserId) },
            role: 'employee',
          };

    const users = await this.prisma.user.findMany({
      where: whereCondition,
      include: { kpis: true },
    });

    const teamMembers = [];
    const today = new Date();

    for (const u of users) {
      const kpis = u.kpis;
      let kpiScorePercent = 0.0;
      if (kpis.length > 0) {
        const totalProgress = kpis.reduce((sum: number, k) => {
          const p = k.targetValue > 0 ? k.currentValue / k.targetValue : 0;
          return sum + (p > 1.0 ? 1.0 : p);
        }, 0);
        kpiScorePercent = totalProgress / kpis.length;
      }

      const leaveStatus = await this.getLeaveStatus(u.id, today);

      teamMembers.push({
        id: u.id,
        name: u.name,
        title: u.title || '',
        department: u.department || '',
        kpiScorePercent,
        leaveStatus,
      });
    }

    return teamMembers;
  }

  async assignKpi(actorUserId: string, actorRole: string, data: AssignKpiDto) {
    const targetUser = await this.prisma.user.findUnique({
      where: { id: data.memberId },
      include: { manager: true },
    });
    if (!targetUser) throw new NotFoundException('Target user not found');

    // Authorize using recursive managed user IDs
    if (actorRole !== 'hr' && actorRole !== 'hrAdmin') {
      const managedIds = await this.getManagedUserIds(actorUserId);
      if (!managedIds.includes(data.memberId)) {
        throw new ForbiddenException(
          'You can only assign KPIs to employees in your reporting chain',
        );
      }
    }

    const kpi = await this.prisma.kpi.create({
      data: {
        userId: data.memberId,
        title: data.title,
        description: data.description || 'Newly assigned KPI',
        departmentObjective:
          data.departmentObjective || 'Improve overall team output',
        targetValue: data.targetValue || 100,
        currentValue: 0,
      },
    });

    this.events.emitEntityUpdated('Kpi', 'updated', kpi);

    return kpi;
  }
}
