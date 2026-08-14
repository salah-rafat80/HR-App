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

interface MockPrismaUser {
  findUnique: jest.Mock;
  update: jest.Mock;
}

interface MockPrismaService {
  user: MockPrismaUser;
}

describe('AuthService Suite - Persistent Secure Login Sessions', () => {
  let service: AuthService;
  let prismaService: MockPrismaService;
  let jwtService: { sign: jest.Mock; verify: jest.Mock };

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
    process.env.JWT_SECRET =
      'test-jwt-secret-min-32-characters-long-1234567890';
    process.env.JWT_REFRESH_SECRET =
      'test-jwt-refresh-secret-min-32-characters-1234567890';

    prismaService = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('valid-signed-jwt-token'),
      verify: jest.fn().mockReturnValue({
        sub: 'user-uuid-1234',
        tokenType: 'refresh',
        aud: 'hr-app-refresh',
        iss: 'hr-app-api',
        iat: 1000000,
      }),
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

  it('1. Successful login with employeeCode and valid password returns signed access_token with correct claims', async () => {
    prismaService.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const result = await service.login('emp-001', 'Password123!');

    expect(prismaService.user.findUnique).toHaveBeenCalledWith({
      where: { employeeCode: 'EMP-001' },
    });
    expect(jwtService.sign).toHaveBeenCalledWith({
      sub: 'user-uuid-1234',
      employeeCode: 'EMP-001',
      role: 'employee',
      tokenType: 'access',
      aud: 'hr-app-access',
      iss: 'hr-app-api',
    });
    expect(result.access_token).toBe('valid-signed-jwt-token');
    expect(result.user.id).toBe('user-uuid-1234');
    expect(result.user.employeeCode).toBe('EMP-001');
  });

  it('2. Login fails when user is not found in database', async () => {
    prismaService.user.findUnique.mockResolvedValue(null);

    await expect(service.login('EMP-999', 'Password123!')).rejects.toThrow(
      UnauthorizedException,
    );
    expect(jwtService.sign).not.toHaveBeenCalled();
  });

  it('3. Login fails when user account is inactive', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      ...mockUser,
      isActive: false,
    });

    await expect(service.login('EMP-001', 'Password123!')).rejects.toThrow(
      UnauthorizedException,
    );
    expect(jwtService.sign).not.toHaveBeenCalled();
  });

  it('4. Login fails when password is incorrect', async () => {
    prismaService.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);

    await expect(service.login('EMP-001', 'WrongPassword')).rejects.toThrow(
      UnauthorizedException,
    );
    expect(jwtService.sign).not.toHaveBeenCalled();
  });

  it('5. Database error during login returns 5xx error', async () => {
    prismaService.user.findUnique.mockRejectedValue(
      new Error('PostgreSQL Connection Failure'),
    );

    await expect(service.login('EMP-001', 'Password123!')).rejects.toThrow(
      InternalServerErrorException,
    );
    expect(jwtService.sign).not.toHaveBeenCalled();
  });

  it('6. Login omits refresh_token when JWT_REFRESH_SECRET is absent', async () => {
    delete process.env.JWT_REFRESH_SECRET;
    prismaService.user.findUnique.mockResolvedValue(mockUser);
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    const res = await service.login('EMP-001', 'Password123!');
    expect(res.access_token).toBeDefined();
    expect((res as Record<string, unknown>).refresh_token).toBeUndefined();
  });

  it('7. refreshToken fails with 401 when JWT_REFRESH_SECRET is not set', async () => {
    delete process.env.JWT_REFRESH_SECRET;
    await expect(service.refreshToken('any-token')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('8. refreshToken throws fatal error if JWT_REFRESH_SECRET is present but shorter than 32 chars', async () => {
    process.env.JWT_REFRESH_SECRET = 'short-secret';
    await expect(service.refreshToken('any-token')).rejects.toThrow(
      'FATAL CONFIGURATION ERROR: JWT_REFRESH_SECRET must be at least 32 characters long',
    );
  });

  it('9. refreshToken rejects access token passed as refresh token (tokenType: access)', async () => {
    jwtService.verify.mockReturnValue({
      sub: 'user-uuid-1234',
      tokenType: 'access',
      aud: 'hr-app-access',
      iss: 'hr-app-api',
      iat: 1000000,
    });

    await expect(service.refreshToken('access-token-string')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('10. refreshToken rejects token if audience or issuer is wrong', async () => {
    jwtService.verify.mockImplementation(() => {
      throw new Error('jwt audience invalid');
    });

    await expect(service.refreshToken('wrong-audience-token')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('11. refreshToken rejects token if passwordChangedAt is after token iat', async () => {
    jwtService.verify.mockReturnValue({
      sub: 'user-uuid-1234',
      tokenType: 'refresh',
      aud: 'hr-app-refresh',
      iss: 'hr-app-api',
      iat: 1000000,
    });

    prismaService.user.findUnique.mockResolvedValue({
      ...mockUser,
      passwordChangedAt: new Date(1000005 * 1000), // changed 5s after token issuance
    });

    await expect(service.refreshToken('valid-refresh-token')).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('12. refreshToken succeeds and issues new access token when token is valid and user is active', async () => {
    jwtService.verify.mockReturnValue({
      sub: 'user-uuid-1234',
      tokenType: 'refresh',
      aud: 'hr-app-refresh',
      iss: 'hr-app-api',
      iat: 1000000,
    });

    prismaService.user.findUnique.mockResolvedValue(mockUser);

    const res = await service.refreshToken('valid-refresh-token');
    expect(res.access_token).toBe('valid-signed-jwt-token');
    expect(res.user.id).toBe('user-uuid-1234');
    expect(res.user.role).toBe('employee');
  });

  it('13. getMe returns safe user object without password or fcmToken', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      ...mockUser,
      fcmToken: 'secret-fcm-token',
    });

    const user = await service.getMe('user-uuid-1234');
    expect(user.id).toBe('user-uuid-1234');
    expect(user.employeeCode).toBe('EMP-001');
    expect((user as Record<string, unknown>).password).toBeUndefined();
    expect((user as Record<string, unknown>).fcmToken).toBeUndefined();
  });
});
