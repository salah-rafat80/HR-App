import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import {
  UnauthorizedException,
  InternalServerErrorException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
}));

describe('AuthService Suite - Real Employee Authentication & Security', () => {
  let service: AuthService;
  let prismaService: any;
  let jwtService: any;

  const mockUser = {
    id: 'user-uuid-1234',
    employeeCode: 'EMP-001',
    email: 'employee@company.com',
    password: '$2b$10$hashedpasswordstring',
    name: 'John Doe',
    role: 'employee',
    isActive: true,
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    prismaService = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('valid-signed-jwt-token'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('1. Successful login with employeeCode and valid password returns signed JWT & user profile', async () => {
    prismaService.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const result = await service.login('emp-001', 'Password123!');

    expect(prismaService.user.findUnique).toHaveBeenCalledWith({
      where: { employeeCode: 'EMP-001' },
    });
    expect(result.access_token).toBe('valid-signed-jwt-token');
    expect(result.user.id).toBe('user-uuid-1234');
    expect(result.user.employeeCode).toBe('EMP-001');
  });

  it('2. Login fails when user is not found in database (no mock fallback)', async () => {
    prismaService.user.findUnique.mockResolvedValue(null);

    await expect(service.login('EMP-999', 'Password123!')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('3. Login fails when user account is inactive', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      ...mockUser,
      isActive: false,
    });

    await expect(service.login('EMP-001', 'Password123!')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('4. Login fails when password is incorrect', async () => {
    prismaService.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    await expect(service.login('EMP-001', 'WrongPassword')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('5. Database error during login returns 5xx/503 Safe Error without demo fallback', async () => {
    prismaService.user.findUnique.mockRejectedValue(
      new Error('PostgreSQL Connection Failure'),
    );

    await expect(service.login('EMP-001', 'Password123!')).rejects.toThrow(
      InternalServerErrorException,
    );
  });

  it('6. Update FCM token persists to database User.id', async () => {
    prismaService.user.update.mockResolvedValue({
      id: 'user-uuid-1234',
      fcmToken: 'fcm-token-val',
    });

    const res = await service.updateFcmToken('user-uuid-1234', 'fcm-token-val');

    expect(prismaService.user.update).toHaveBeenCalledWith({
      where: { id: 'user-uuid-1234' },
      data: { fcmToken: 'fcm-token-val' },
    });
    expect(res.success).toBe(true);
  });
});
