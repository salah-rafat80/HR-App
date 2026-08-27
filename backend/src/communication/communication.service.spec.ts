/* eslint-disable @typescript-eslint/unbound-method */
import { Test, TestingModule } from '@nestjs/testing';
import { CommunicationService } from './communication.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notifications/notification.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { Logger } from '@nestjs/common';

describe('CommunicationService', () => {
  let service: CommunicationService;
  let prismaService: {
    announcement: {
      create: jest.Mock;
      findMany: jest.Mock;
    };
    user: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
    };
  };
  let notificationService: {
    notifyNewAnnouncement: jest.Mock;
  };

  beforeEach(async () => {
    prismaService = {
      announcement: {
        create: jest.fn(),
        findMany: jest.fn(),
      },
      user: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
      },
    };

    notificationService = {
      notifyNewAnnouncement: jest
        .fn()
        .mockResolvedValue({ successCount: 0, failureCount: 0 }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommunicationService,
        { provide: PrismaService, useValue: prismaService },
        { provide: NotificationService, useValue: notificationService },
      ],
    }).compile();

    service = module.get<CommunicationService>(CommunicationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create an announcement and scope to recipient department', async () => {
      const dto: CreateAnnouncementDto = {
        title: 'Test',
        content: 'Test content',
        department: 'IT',
      };
      const createdAnnouncement = {
        id: 'a1',
        ...dto,
        authorId: 'auth-user-id',
      };
      prismaService.announcement.create.mockResolvedValue(createdAnnouncement);
      prismaService.user.findMany.mockResolvedValue([{ fcmToken: 'token1' }]);

      await service.create(dto, 'auth-user-id');

      expect(prismaService.user.findMany).toHaveBeenCalledWith({
        where: {
          fcmToken: { not: null },
          isActive: true,
          department: 'IT',
        },
        select: { fcmToken: true },
      });
      // The push notifications are not awaited, but we mock the internal function or the service.
      // Wait, we mocked notificationService.notifyNewAnnouncement, let's verify if it was called.
      // Since sendNotificationsChunked is async, we need a small delay for the promise to resolve in test.
      await new Promise(process.nextTick);
      expect(notificationService.notifyNewAnnouncement).toHaveBeenCalledWith(
        ['token1'],
        'Test',
        'Test content',
        'a1',
      );
    });

    it('should chunk FCM notifications and aggregate results correctly', async () => {
      const dto: CreateAnnouncementDto = {
        title: 'Test Chunk',
        content: 'Content',
      };
      const createdAnnouncement = {
        id: 'a3',
        ...dto,
        authorId: 'auth-user-id',
      };
      prismaService.announcement.create.mockResolvedValue(createdAnnouncement);

      const tokens = Array.from({ length: 1200 }).map((_, i) => ({
        fcmToken: `token${i}`,
      }));
      prismaService.user.findMany.mockResolvedValue(tokens);

      notificationService.notifyNewAnnouncement
        .mockResolvedValueOnce({ successCount: 500, failureCount: 0 }) // First 500
        .mockResolvedValueOnce({ successCount: 400, failureCount: 100 }) // Next 500
        .mockResolvedValueOnce({ successCount: 150, failureCount: 50 }); // Last 200

      const loggerSpy = jest.spyOn(Logger.prototype, 'log');

      await service.create(dto, 'auth-user-id');
      await new Promise(process.nextTick);

      expect(notificationService.notifyNewAnnouncement).toHaveBeenCalledTimes(
        3,
      );
      expect(notificationService.notifyNewAnnouncement).toHaveBeenNthCalledWith(
        1,
        tokens.slice(0, 500).map((t) => t.fcmToken),
        'Test Chunk',
        'Content',
        'a3',
      );
      expect(notificationService.notifyNewAnnouncement).toHaveBeenNthCalledWith(
        3,
        tokens.slice(1000, 1200).map((t) => t.fcmToken),
        'Test Chunk',
        'Content',
        'a3',
      );

      expect(loggerSpy).toHaveBeenCalledWith(
        'Push notifications for announcement a3: 1050 sent, 150 failed.',
      );
    });

    it('should aggregate failed chunks as completely failed and not crash', async () => {
      const dto: CreateAnnouncementDto = {
        title: 'Error Chunk',
        content: 'Content',
      };
      const createdAnnouncement = {
        id: 'a4',
        ...dto,
        authorId: 'auth-user-id',
      };
      prismaService.announcement.create.mockResolvedValue(createdAnnouncement);

      const tokens = Array.from({ length: 600 }).map((_, i) => ({
        fcmToken: `token${i}`,
      }));
      prismaService.user.findMany.mockResolvedValue(tokens);

      notificationService.notifyNewAnnouncement
        .mockRejectedValueOnce(new Error('Firebase Unavailable')) // first 500 fails completely
        .mockResolvedValueOnce({ successCount: 100, failureCount: 0 }); // last 100 succeeds

      const loggerErrorSpy = jest
        .spyOn(Logger.prototype, 'error')
        .mockImplementation();
      const loggerLogSpy = jest
        .spyOn(Logger.prototype, 'log')
        .mockImplementation();

      await service.create(dto, 'auth-user-id');
      await new Promise(process.nextTick);

      expect(notificationService.notifyNewAnnouncement).toHaveBeenCalledTimes(
        2,
      );
      expect(loggerErrorSpy).toHaveBeenCalledWith(
        'Failed to send chunk starting at index 0',
        expect.any(Error),
      );
      expect(loggerLogSpy).toHaveBeenCalledWith(
        'Push notifications for announcement a4: 100 sent, 500 failed.',
      );
    });

    it('should create an announcement without department scoping if no department is specified', async () => {
      const dto: CreateAnnouncementDto = {
        title: 'Global',
        content: 'Global content',
      };
      const createdAnnouncement = {
        id: 'a2',
        ...dto,
        authorId: 'auth-user-id',
      };
      prismaService.announcement.create.mockResolvedValue(createdAnnouncement);
      prismaService.user.findMany.mockResolvedValue([
        { fcmToken: 'token1' },
        { fcmToken: 'token2' },
      ]);

      await service.create(dto, 'auth-user-id');

      expect(prismaService.user.findMany).toHaveBeenCalledWith({
        where: {
          fcmToken: { not: null },
          isActive: true,
        },
        select: { fcmToken: true },
      });
      await new Promise(process.nextTick);
      expect(notificationService.notifyNewAnnouncement).toHaveBeenCalledWith(
        ['token1', 'token2'],
        'Global',
        'Global content',
        'a2',
      );
    });

    it('should handle failed or empty FCM tokens gracefully', async () => {
      const dto: CreateAnnouncementDto = {
        title: 'No Tokens',
        content: 'No one has tokens',
      };
      const createdAnnouncement = {
        id: 'a3',
        ...dto,
        authorId: 'auth-user-id',
      };
      prismaService.announcement.create.mockResolvedValue(createdAnnouncement);
      // Return empty or null tokens (e.g. users without tokens are filtered out by DB anyway)
      prismaService.user.findMany.mockResolvedValue([{ fcmToken: null }, {}]);

      await service.create(dto, 'auth-user-id');

      await new Promise(process.nextTick);
      // Notification shouldn't be fired if tokens list is empty
      expect(notificationService.notifyNewAnnouncement).not.toHaveBeenCalled();
    });
  });

  describe('findAll', () => {
    it('should return announcements without exposing sensitive user data', async () => {
      prismaService.announcement.findMany.mockResolvedValue([
        {
          id: 'a1',
          author: { id: 'u1', name: 'John Doe' },
        },
      ]);

      prismaService.user.findUnique.mockResolvedValue({ department: null });
      const result = await service.findAll('u1');
      expect(result).toEqual([
        { id: 'a1', author: { id: 'u1', name: 'John Doe' } },
      ]);
      expect(prismaService.announcement.findMany).toHaveBeenCalledWith({
        where: {
          OR: [{ department: null }],
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
    });

    it('should return announcements filtered by user department and global', async () => {
      prismaService.user.findUnique.mockResolvedValue({ department: 'HR' });
      prismaService.announcement.findMany.mockResolvedValue([
        { id: 'a1', author: { id: 'u1', name: 'John Doe' } },
      ]);

      const result = await service.findAll('u1');
      expect(result).toEqual([
        { id: 'a1', author: { id: 'u1', name: 'John Doe' } },
      ]);
      expect(prismaService.announcement.findMany).toHaveBeenCalledWith({
        where: {
          OR: [{ department: null }, { department: 'HR' }],
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
    });
  });
});
