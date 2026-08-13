import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: { login: jest.Mock; updateFcmToken: jest.Mock };

  beforeEach(async () => {
    authService = {
      login: jest.fn(),
      updateFcmToken: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: authService,
        },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
  });

  it('1. signIn delegates employeeCode and password to AuthService', async () => {
    authService.login.mockResolvedValue({ access_token: 'signed-token' });

    const dto = { employeeCode: 'EMP-001', password: 'Password123!' };
    const res = (await controller.signIn(dto)) as { access_token: string };

    expect(authService.login).toHaveBeenCalledWith('EMP-001', 'Password123!');
    expect(res.access_token).toBe('signed-token');
  });

  it('2. FCM update prevents cross-user modification by strictly using req.user.userId from authenticated JWT', async () => {
    authService.updateFcmToken.mockResolvedValue({ success: true });

    // User A is authenticated in req.user
    const req = {
      user: { userId: 'user-A-uuid', role: 'employee' },
    };
    const dto = { fcmToken: 'new-fcm-token-for-user-A' };

    const res = (await controller.updateFcmToken(req, dto)) as {
      success: boolean;
    };

    // Asserts that update is scoped to 'user-A-uuid' regardless of client input
    expect(authService.updateFcmToken).toHaveBeenCalledWith(
      'user-A-uuid',
      'new-fcm-token-for-user-A',
    );
    expect(res.success).toBe(true);
  });
});
