import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: any;

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
    const res = await controller.signIn(dto);

    expect(authService.login).toHaveBeenCalledWith('EMP-001', 'Password123!');
    expect(res.access_token).toBe('signed-token');
  });

  it('2. updateFcmToken uses authenticated req.user.userId', async () => {
    authService.updateFcmToken.mockResolvedValue({ success: true });

    const req = { user: { userId: 'user-uuid-1234' } };
    const dto = { fcmToken: 'fcm-token-val' };
    const res = await controller.updateFcmToken(req, dto);

    expect(authService.updateFcmToken).toHaveBeenCalledWith(
      'user-uuid-1234',
      'fcm-token-val',
    );
    expect(res.success).toBe(true);
  });
});
