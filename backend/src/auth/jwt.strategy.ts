import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { getJwtSecret } from './jwt-secret.helper';

export interface JwtPayload {
  sub: string;
  employeeCode?: string;
  role: string;
  tokenType?: string;
  aud?: string;
  iss?: string;
  iat?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: getJwtSecret(),
      audience: 'hr-app-access',
      issuer: 'hr-app-api',
    });
  }

  validate(payload: JwtPayload) {
    if (
      !payload ||
      !payload.sub ||
      payload.tokenType !== 'access' ||
      payload.aud !== 'hr-app-access' ||
      payload.iss !== 'hr-app-api'
    ) {
      throw new UnauthorizedException('Invalid access token claims');
    }
    return {
      userId: payload.sub,
      employeeCode: payload.employeeCode,
      role: payload.role,
    };
  }
}
