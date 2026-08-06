import { Controller, Post, Body, HttpCode, HttpStatus, Patch } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @HttpCode(HttpStatus.OK)
  @Post('login')
  signIn(@Body() signInDto: Record<string, any>) {
    return this.authService.login(signInDto.email, signInDto.password);
  }

  @HttpCode(HttpStatus.OK)
  @Patch('fcm-token')
  updateFcmToken(@Body() body: { email: string; token: string }) {
    return this.authService.updateFcmToken(body.email, body.token);
  }
}

