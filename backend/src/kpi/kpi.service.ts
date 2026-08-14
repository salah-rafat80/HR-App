import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { AssignKpiDto } from './dto/kpi.dto';
import { Kpi, KpiQuarterScore } from '@prisma/client';

export interface TeamMember {
  id: string;
  name: string;
  title: string;
  department: string;
  kpiScorePercent: number;
  leaveStatus: string;
}

@Injectable()
export class KpiService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  async getCurrentKpis(userId: string): Promise<Kpi[]> {
    return this.prisma.kpi.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getHistoricalScores(userId: string): Promise<KpiQuarterScore[]> {
    return this.prisma.kpiQuarterScore.findMany({
      where: { userId },
      orderBy: { quarterLabel: 'desc' },
    });
  }

  async submitSelfAssessment(
    userId: string,
    kpiId: string,
    text: string,
  ): Promise<Kpi> {
    const kpi = await this.prisma.kpi.findUnique({
      where: { id: kpiId },
    });

    if (!kpi) throw new NotFoundException('KPI not found');
    if (kpi.userId !== userId) {
      throw new ForbiddenException(
        'You can only submit self-assessment for your own KPIs',
      );
    }

    let newCurrent = kpi.currentValue + kpi.targetValue * 0.05;
    if (newCurrent > kpi.targetValue) newCurrent = kpi.targetValue;

    const updated = await this.prisma.kpi.update({
      where: { id: kpiId },
      data: {
        selfAssessmentText: text,
        currentValue: newCurrent,
      },
    });

    this.events.emitEntityUpdated('Kpi', 'updated', updated);

    return updated;
  }

  async attachEvidence(userId: string, kpiId: string): Promise<Kpi> {
    const kpi = await this.prisma.kpi.findUnique({
      where: { id: kpiId },
    });

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

  async getOverallQuarterScore(
    userId: string,
  ): Promise<{ overallScore: number }> {
    const kpis = await this.prisma.kpi.findMany({
      where: { userId },
      select: { currentValue: true, targetValue: true },
    });

    if (kpis.length === 0) return { overallScore: 0.0 };

    const totalProgress = kpis.reduce((sum: number, kpi) => {
      const p = kpi.targetValue > 0 ? kpi.currentValue / kpi.targetValue : 0;
      return sum + (p > 1.0 ? 1.0 : p);
    }, 0);

    return { overallScore: totalProgress / kpis.length };
  }

  /**
   * Optimized Breadth-First-Search resolution of managed reporting chain IDs.
   * Uses a visited Set to prevent infinite loops or duplicate IDs if data contains cyclic reporting managerId links.
   * Runs in O(depth) database queries instead of O(N) recursive individual user queries.
   */
  async getManagedUserIds(actorUserId: string): Promise<string[]> {
    let currentLevelIds = [actorUserId];
    const allManagedIds: string[] = [];
    const visited = new Set<string>([actorUserId]);

    while (currentLevelIds.length > 0) {
      const nextLevel = await this.prisma.user.findMany({
        where: { managerId: { in: currentLevelIds } },
        select: { id: true },
      });
      if (nextLevel.length === 0) break;

      const nextIds: string[] = [];
      for (const u of nextLevel) {
        if (!visited.has(u.id)) {
          visited.add(u.id);
          nextIds.push(u.id);
        }
      }
      if (nextIds.length === 0) break;

      allManagedIds.push(...nextIds);
      currentLevelIds = nextIds;
    }

    return allManagedIds;
  }

  /**
   * Optimized batch Team KPI endpoint:
   * 1. Fetches managed employee users and their KPIs in one query.
   * 2. Bulk fetches active leave requests & WFH attendance records for all team members in 2 parallel queries.
   * Eliminates the N+1 loop (reducing DB queries from 1 + 2N to 3 total).
   */
  async getTeamKpis(
    actorUserId: string,
    actorRole: string,
  ): Promise<TeamMember[]> {
    let whereCondition:
      { role: string } | { id: { in: string[] }; role: string };

    if (actorRole === 'hr' || actorRole === 'hrAdmin') {
      whereCondition = { role: 'employee' };
    } else {
      const managedIds = await this.getManagedUserIds(actorUserId);
      if (managedIds.length === 0) return [];
      whereCondition = {
        id: { in: managedIds },
        role: 'employee',
      };
    }

    const users = await this.prisma.user.findMany({
      where: whereCondition,
      select: {
        id: true,
        name: true,
        title: true,
        department: true,
        kpis: {
          select: {
            currentValue: true,
            targetValue: true,
          },
        },
      },
    });

    if (users.length === 0) return [];

    const userIds = users.map((u) => u.id);
    const today = new Date();
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

    // Perform bulk queries for active leave & WFH attendance to avoid N+1 queries
    const activeLeaves = await this.prisma.leaveRequest.findMany({
      where: {
        userId: { in: userIds },
        overallStatus: 'approved',
        startDate: { lte: today },
        endDate: { gte: today },
      },
      select: { userId: true },
    });

    const wfhRecords = await this.prisma.attendanceRecord.findMany({
      where: {
        userId: { in: userIds },
        status: 'workFromHome',
        date: { gte: startOfDay, lte: endOfDay },
      },
      select: { userId: true },
    });

    const onLeaveUserIds = new Set(activeLeaves.map((l) => l.userId));
    const wfhUserIds = new Set(wfhRecords.map((a) => a.userId));

    return users.map((u): TeamMember => {
      const kpis = u.kpis ?? [];
      let kpiScorePercent = 0.0;
      if (kpis.length > 0) {
        const totalProgress = kpis.reduce((sum: number, k) => {
          const p = k.targetValue > 0 ? k.currentValue / k.targetValue : 0;
          return sum + (p > 1.0 ? 1.0 : p);
        }, 0);
        kpiScorePercent = totalProgress / kpis.length;
      }

      let leaveStatus = 'present';
      if (onLeaveUserIds.has(u.id)) {
        leaveStatus = 'onLeave';
      } else if (wfhUserIds.has(u.id)) {
        leaveStatus = 'wfh';
      }

      return {
        id: u.id,
        name: u.name,
        title: u.title ?? '',
        department: u.department ?? '',
        kpiScorePercent,
        leaveStatus,
      };
    });
  }

  async assignKpi(
    actorUserId: string,
    actorRole: string,
    data: AssignKpiDto,
  ): Promise<Kpi> {
    const targetUser = await this.prisma.user.findUnique({
      where: { id: data.memberId },
      select: { id: true, managerId: true },
    });

    if (!targetUser) throw new NotFoundException('Target user not found');

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

    this.events.emitEntityUpdated('Kpi', 'updated', updatedKpi(kpi));

    return kpi;
  }
}

function updatedKpi(k: Kpi): Kpi {
  return k;
}
