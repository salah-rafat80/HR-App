import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notifications/notification.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';

@Injectable()
export class CommunicationService {
  private readonly logger = new Logger(CommunicationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationService: NotificationService,
  ) {}

  async create(createAnnouncementDto: CreateAnnouncementDto, authorId: string) {
    const announcement = await this.prisma.announcement.create({
      data: {
        title: createAnnouncementDto.title,
        content: createAnnouncementDto.content,
        department: createAnnouncementDto.department || null,
        authorId: authorId,
      },
    });

    // Fetch all users with FCM tokens (or filter by department if specified)
    const users = await this.prisma.user.findMany({
      where: {
        fcmToken: { not: null },
        isActive: true,
        ...(createAnnouncementDto.department
          ? { department: createAnnouncementDto.department }
          : {}),
      },
      select: { fcmToken: true },
    });

    const tokens = users.map((u) => u.fcmToken).filter(Boolean) as string[];

    // Fire the push notification to all matched users (chunked into 500)
    if (tokens.length > 0) {
      // Async without awaiting to prevent blocking the response or rolling back on error
      this.sendNotificationsChunked(
        tokens,
        announcement.title,
        announcement.content,
        announcement.id,
      ).catch((err) =>
        this.logger.error(
          `Failed to dispatch push notifications: ${(err as Error).message}`,
          (err as Error).stack,
        ),
      );
    }

    return announcement;
  }

  private async sendNotificationsChunked(
    tokens: string[],
    title: string,
    content: string,
    announcementId: string,
  ) {
    const chunkSize = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);
      try {
        const result = await this.notificationService.notifyNewAnnouncement(
          chunk,
          title,
          content,
          announcementId,
        );
        successCount += result.successCount;
        failureCount += result.failureCount;
      } catch (error) {
        failureCount += chunk.length;
        this.logger.error(`Failed to send chunk starting at index ${i}`, error);
      }
    }

    this.logger.log(
      `Push notifications for announcement ${announcementId}: ${successCount} sent, ${failureCount} failed.`,
    );
  }

  async findAll(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { department: true },
    });

    return this.prisma.announcement.findMany({
      where: {
        OR: [
          { department: null },
          user?.department ? { department: user.department } : undefined,
        ].filter(Boolean) as Record<string, any>[],
      },
      orderBy: { createdAt: 'desc' },
      include: {
        author: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }
}
