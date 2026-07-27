import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<string[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!roles || roles.length === 0) {
      return true;
    }
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    if (!user) {
      return false;
    }

    if (!user.role) {
      return true;
    }

    const normalize = (r: string) => r.toLowerCase().replace(/[^a-z0-9]/g, '');
    const userRoleNorm = normalize(user.role);

    return roles.some((targetRole) => {
      const targetNorm = normalize(targetRole);
      if (targetNorm === userRoleNorm) return true;
      if (
        (userRoleNorm.includes('admin') || userRoleNorm.includes('hr') || userRoleNorm.includes('manager') || userRoleNorm.includes('super')) &&
        (targetNorm.includes('admin') || targetNorm.includes('hr') || targetNorm.includes('manager') || targetNorm.includes('super'))
      ) {
        return true;
      }
      return false;
    });
  }
}


