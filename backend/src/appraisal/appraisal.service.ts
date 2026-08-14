import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../events/events/events.gateway';
import { SelfAppraisalAnswerItemDto } from './dto/appraisal.dto';

@Injectable()
export class AppraisalService {
  constructor(
    private prisma: PrismaService,
    private events: EventsGateway,
  ) {}

  async getCurrentCycle(userId: string) {
    const cycle = await this.prisma.appraisalCycle.findFirst({
      where: { status: { in: ['inProgress', 'upcoming'] } },
      orderBy: { createdAt: 'desc' },
    });

    if (!cycle) {
      return {
        cycleLabel: 'No Active Cycle',
        status: 'completed',
        dueDate: new Date(),
        selfAppraisalSubmitted: false,
      };
    }

    const answerCount = await this.prisma.selfAppraisalAnswer.count({
      where: { userId, cycleId: cycle.id },
    });

    return {
      cycleLabel: cycle.label,
      status: cycle.status,
      dueDate: cycle.dueDate,
      selfAppraisalSubmitted: answerCount > 0,
    };
  }

  getSelfAppraisalQuestions() {
    return [
      { id: 'q1', questionText: 'What were your key achievements this cycle?' },
      { id: 'q2', questionText: 'What challenges did you face?' },
      { id: 'q3', questionText: 'How did you live our core values?' },
      { id: 'q4', questionText: 'What support do you need going forward?' },
      { id: 'q5', questionText: 'What are your goals for the next cycle?' },
    ];
  }

  async submitSelfAppraisal(
    userId: string,
    answers: SelfAppraisalAnswerItemDto[],
  ) {
    const cycle = await this.prisma.appraisalCycle.findFirst({
      where: { status: 'inProgress' },
      orderBy: { createdAt: 'desc' },
    });

    if (!cycle) {
      throw new NotFoundException('No active appraisal cycle in progress');
    }

    for (const ans of answers) {
      await this.prisma.selfAppraisalAnswer.upsert({
        where: {
          userId_cycleId_questionId: {
            userId,
            cycleId: cycle.id,
            questionId: ans.id,
          },
        },
        create: {
          userId,
          cycleId: cycle.id,
          questionId: ans.id,
          questionText: ans.questionText,
          answerText: ans.answerText || '',
        },
        update: {
          answerText: ans.answerText || '',
        },
      });
    }

    const updatedStatus = await this.getCurrentCycle(userId);

    this.events.emitEntityUpdated('AppraisalCycle', 'updated', updatedStatus);

    return { success: true };
  }

  async getPeersForFeedback(userId: string) {
    const colleagues = await this.prisma.user.findMany({
      where: { id: { not: userId } },
      take: 5,
    });

    const cycle = await this.prisma.appraisalCycle.findFirst({
      where: { status: 'inProgress' },
      orderBy: { createdAt: 'desc' },
    });

    const peerFeedbacks: Array<{
      colleague: {
        id: string;
        name: string;
        role: string;
        avatarInitial: string;
      };
      feedbackText: string | null;
      submitted: boolean;
    }> = [];
    for (const col of colleagues) {
      const feedback = cycle
        ? await this.prisma.peerFeedback.findUnique({
            where: {
              fromUserId_toUserId_cycleId: {
                fromUserId: userId,
                toUserId: col.id,
                cycleId: cycle.id,
              },
            },
          })
        : null;

      peerFeedbacks.push({
        colleague: {
          id: col.id,
          name: col.name,
          role: col.title || col.role,
          avatarInitial: col.name.charAt(0).toUpperCase(),
        },
        feedbackText: feedback?.feedbackText || null,
        submitted: feedback?.submitted || false,
      });
    }

    return peerFeedbacks;
  }

  async submitPeerFeedback(userId: string, colleagueId: string, text: string) {
    if (userId === colleagueId) {
      throw new BadRequestException(
        'You cannot submit peer feedback for yourself',
      );
    }

    const cycle = await this.prisma.appraisalCycle.findFirst({
      where: { status: 'inProgress' },
      orderBy: { createdAt: 'desc' },
    });

    if (!cycle) {
      throw new NotFoundException('No active appraisal cycle in progress');
    }

    const updated = await this.prisma.peerFeedback.upsert({
      where: {
        fromUserId_toUserId_cycleId: {
          fromUserId: userId,
          toUserId: colleagueId,
          cycleId: cycle.id,
        },
      },
      create: {
        fromUserId: userId,
        toUserId: colleagueId,
        cycleId: cycle.id,
        feedbackText: text,
        submitted: true,
      },
      update: {
        feedbackText: text,
        submitted: true,
      },
    });

    this.events.emitEntityUpdated('AppraisalCycle', 'updated', {
      cycleLabel: cycle.label,
      status: cycle.status,
      dueDate: cycle.dueDate,
    });

    return updated;
  }

  async getMyResults(userId: string) {
    const cycle = await this.prisma.appraisalCycle.findFirst({
      orderBy: { createdAt: 'desc' },
    });

    const ratings = cycle
      ? await this.prisma.appraisalCategoryRating.findMany({
          where: { userId, cycleId: cycle.id },
        })
      : [];

    if (ratings.length === 0) {
      return {
        overallRating: 0.0,
        categoryRatings: [],
        managerSummary: 'No appraisal ratings recorded for this cycle yet.',
      };
    }

    const overallRating =
      ratings.reduce((sum, r) => sum + r.score, 0) / ratings.length;

    return {
      overallRating: parseFloat(overallRating.toFixed(1)),
      categoryRatings: ratings.map((r) => ({
        categoryName: r.categoryName,
        score: r.score,
        managerComment: r.managerComment,
      })),
      managerSummary: 'Appraisal cycle ratings completed.',
    };
  }

  async getDevelopmentPlan(userId: string) {
    const goals = await this.prisma.developmentGoal.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });

    return goals.map((g) => ({
      title: g.title,
      progressPercent: g.progressPercent,
    }));
  }

  async getCareerPath(userId: string) {
    const steps = await this.prisma.careerStep.findMany({
      where: { userId },
      orderBy: { order: 'asc' },
    });

    return steps.map((s) => ({
      roleTitle: s.roleTitle,
      status: s.status,
    }));
  }

  async startNewCycle(
    userId: string,
    userRole: string,
    label: string,
    dueDate: Date,
  ) {
    const normalizedRole = userRole.toLowerCase().replace(/[^a-z0-9]/g, '');
    if (
      normalizedRole !== 'hradmin' &&
      normalizedRole !== 'superadmin' &&
      normalizedRole !== 'hr'
    ) {
      throw new ForbiddenException(
        'Only HR Admins can initialize a new appraisal cycle',
      );
    }

    await this.prisma.appraisalCycle.updateMany({
      where: { status: { in: ['inProgress', 'upcoming'] } },
      data: { status: 'completed' },
    });

    const cycle = await this.prisma.appraisalCycle.create({
      data: {
        label,
        dueDate,
        status: 'inProgress',
      },
    });

    const updatedStatus = {
      cycleLabel: cycle.label,
      status: cycle.status,
      dueDate: cycle.dueDate,
      selfAppraisalSubmitted: false,
    };

    this.events.emitEntityUpdated('AppraisalCycle', 'updated', updatedStatus);

    return updatedStatus;
  }
}
