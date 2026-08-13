import { Reflector } from '@nestjs/core';
import { ExecutionContext } from '@nestjs/common';
import { RolesGuard } from './roles.guard';
import { Role } from './roles.enum';

describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    guard = new RolesGuard(reflector);
  });

  function createMockContext(user: { role?: string } | null): ExecutionContext {
    return {
      getHandler: () => ({}),
      getClass: () => ({}),
      switchToHttp: () => ({
        getRequest: () => ({ user }),
      }),
    } as unknown as ExecutionContext;
  }

  it('should allow access when no roles are required', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const context = createMockContext({ role: Role.employee });
    expect(guard.canActivate(context)).toBe(true);
  });

  it('should deny access when user is missing', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.hrAdmin]);
    const context = createMockContext(null);
    expect(guard.canActivate(context)).toBe(false);
  });

  it('should allow superAdmin access to any protected route', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.hrAdmin]);
    const context = createMockContext({ role: Role.superAdmin });
    expect(guard.canActivate(context)).toBe(true);
  });

  it('should allow access when user role strictly matches required role', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.hrAdmin]);
    const context = createMockContext({ role: Role.hrAdmin });
    expect(guard.canActivate(context)).toBe(true);
  });

  it('should DENY access to hr role when hrAdmin is required (no implicit merging)', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.hrAdmin]);
    const context = createMockContext({ role: Role.hr });
    expect(guard.canActivate(context)).toBe(false);
  });

  it('should DENY access to employee role when manager is required', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([Role.manager]);
    const context = createMockContext({ role: Role.employee });
    expect(guard.canActivate(context)).toBe(false);
  });
});
