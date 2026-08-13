import {
  Injectable,
  UnauthorizedException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';

interface FailureRecord {
  count: number;
  lastAttempt: number;
}

@Injectable()
export class AuthService {
  /**
   * SECURITY DOCUMENTATION:
   * This in-memory failure map provides single-instance temporary rate-limiting protection
   * against progressive password guessing per employeeCode. It is suitable for single-node
   * application instances. For multi-instance distributed deployments, a distributed store
   * (e.g. Redis Throttler store) must replace this temporary in-memory map.
   */
  private failureMap = new Map<string, FailureRecord>();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  private async applyProgressiveDelay(employeeCode: string): Promise<number> {
    const record = this.failureMap.get(employeeCode);
    if (!record || record.count <= 0) return 0;

    let delayMs = 0;
    if (record.count === 2) delayMs = 1000;
    else if (record.count === 3) delayMs = 2000;
    else if (record.count >= 4) delayMs = 5000;

    if (delayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
    return delayMs;
  }

  private recordFailure(employeeCode: string): void {
    const record = this.failureMap.get(employeeCode) || {
      count: 0,
      lastAttempt: Date.now(),
    };
    record.count += 1;
    record.lastAttempt = Date.now();
    this.failureMap.set(employeeCode, record);
  }

  private clearFailures(employeeCode: string): void {
    this.failureMap.delete(employeeCode);
  }

  async login(employeeCode: string, pass: string) {
    if (!employeeCode || !pass) {
      throw new UnauthorizedException(
        'Employee code and password are required',
      );
    }

    const normalizedCode = employeeCode.trim().toUpperCase();

    // Apply progressive delay for repeated failed attempts
    await this.applyProgressiveDelay(normalizedCode);

    let user: User | null = null;
    try {
      user = await this.prisma.user.findUnique({
        where: { employeeCode: normalizedCode },
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error('Database connection error during login:', msg);
      throw new InternalServerErrorException(
        'Database access failure. Please try again later.',
      );
    }

    if (!user) {
      this.recordFailure(normalizedCode);
      throw new UnauthorizedException('Invalid employee code or password');
    }

    if (user.isActive === false) {
      this.recordFailure(normalizedCode);
      throw new UnauthorizedException('Employee account is inactive');
    }

    const isMatch = await bcrypt.compare(pass, user.password);
    if (!isMatch) {
      this.recordFailure(normalizedCode);
      throw new UnauthorizedException('Invalid employee code or password');
    }

    // Clear failed attempts counter on successful login
    this.clearFailures(normalizedCode);

    const payload = {
      sub: user.id,
      employeeCode: user.employeeCode,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        employeeCode: user.employeeCode,
        email: user.email,
        name: user.name,
        role: user.role,
        isActive: user.isActive,
      },
    };
  }

  async updateFcmToken(userId: string, token: string) {
    try {
      await this.prisma.user.update({
        where: { id: userId },
        data: { fcmToken: token },
      });
      return { success: true, message: 'FCM token updated successfully' };
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error('Failed to update FCM token for user:', userId, msg);
      throw new InternalServerErrorException(
        'Failed to persist FCM token to database',
      );
    }
  }
}
