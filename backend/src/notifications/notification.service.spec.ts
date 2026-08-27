import { Test, TestingModule } from '@nestjs/testing';
import { NotificationService } from './notification.service';
import * as firebaseAdminApp from 'firebase-admin/app';
import * as firebaseAdminMessaging from 'firebase-admin/messaging';

jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(),
  cert: jest.fn(),
}));

jest.mock('firebase-admin/messaging', () => ({
  getMessaging: jest.fn(),
}));

describe('NotificationService', () => {
  let service: NotificationService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [NotificationService],
    }).compile();

    service = module.get<NotificationService>(NotificationService);
  });

  describe('notifyNewAnnouncement', () => {
    it('should return 0 successes and full failure count if Firebase is unavailable', async () => {
      (firebaseAdminApp.getApps as jest.Mock).mockReturnValue([]);
      // Do not initialize properly so it remains unavailable

      const result = await service.notifyNewAnnouncement(
        ['token1', 'token2'],
        'Title',
        'Body',
      );
      expect(result).toEqual({ successCount: 0, failureCount: 2 });
    });

    it('should return exact successCount and failureCount from Firebase', async () => {
      (firebaseAdminApp.getApps as jest.Mock).mockReturnValue([
        { name: '[DEFAULT]' },
      ]);

      const mockSendEachForMulticast = jest.fn().mockResolvedValue({
        successCount: 1,
        failureCount: 1,
      });

      (firebaseAdminMessaging.getMessaging as jest.Mock).mockReturnValue({
        sendEachForMulticast: mockSendEachForMulticast,
      });

      service.onModuleInit(); // To set isReady to true

      const result = await service.notifyNewAnnouncement(
        ['token1', 'token2'],
        'Title',
        'Body',
      );

      expect(result).toEqual({ successCount: 1, failureCount: 1 });
      expect(mockSendEachForMulticast).toHaveBeenCalledWith(
        expect.objectContaining({
          tokens: ['token1', 'token2'],
        }),
      );
    });

    it('should return 0 successes and full failure count if Firebase sendEachForMulticast rejects completely', async () => {
      (firebaseAdminApp.getApps as jest.Mock).mockReturnValue([
        { name: '[DEFAULT]' },
      ]);

      const mockSendEachForMulticast = jest
        .fn()
        .mockRejectedValue(new Error('Firebase Network Error'));

      (firebaseAdminMessaging.getMessaging as jest.Mock).mockReturnValue({
        sendEachForMulticast: mockSendEachForMulticast,
      });

      const consoleErrorSpy = jest
        .spyOn(service['logger'], 'error')
        .mockImplementation(() => {});

      service.onModuleInit();

      const result = await service.notifyNewAnnouncement(
        ['token1', 'token2'],
        'Title',
        'Body',
      );

      expect(result).toEqual({ successCount: 0, failureCount: 2 });
      expect(consoleErrorSpy).toHaveBeenCalled();
      const loggedArgs = consoleErrorSpy.mock.calls.flat().join(' ');
      expect(loggedArgs).not.toContain('token1');
      expect(loggedArgs).not.toContain('token2');

      consoleErrorSpy.mockRestore();
    });
  });
});
