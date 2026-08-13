import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
  Controller,
  Post,
  Body,
  Get,
} from '@nestjs/common';
import request from 'supertest';
import helmet from 'helmet';
import * as express from 'express';
import { IsNotEmpty, IsString } from 'class-validator';

class TestDto {
  @IsNotEmpty()
  @IsString()
  field!: string;
}

@Controller('test-security')
class TestSecurityController {
  @Get('headers')
  getHeaders() {
    return { ok: true };
  }

  @Post('validate')
  validateDto(@Body() dto: TestDto) {
    return dto;
  }
}

describe('Main App Security Configuration', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [TestSecurityController],
    }).compile();

    app = moduleFixture.createNestApplication();

    // Replicate main.ts security configuration
    app.use(helmet());

    const httpAdapter = app.getHttpAdapter();
    if (httpAdapter) {
      const expressApp = httpAdapter.getInstance() as {
        disable?: (setting: string) => void;
      };
      if (expressApp && typeof expressApp.disable === 'function') {
        expressApp.disable('x-powered-by');
      }
    }

    app.use(express.json({ limit: '100kb' }));
    app.use(express.urlencoded({ extended: true, limit: '100kb' }));

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should disable x-powered-by header and set Helmet security headers', async () => {
    const response = await request(app.getHttpServer()).get(
      '/test-security/headers',
    );
    expect(response.headers['x-powered-by']).toBeUndefined();
    expect(response.headers['x-content-type-options']).toBe('nosniff');
  });

  it('should reject non-whitelisted request properties via global ValidationPipe', async () => {
    const response = await request(app.getHttpServer())
      .post('/test-security/validate')
      .send({
        field: 'validValue',
        maliciousExtraField: 'hacked',
      });

    expect(response.status).toBe(400);
    expect(JSON.stringify(response.body)).toContain(
      'property maliciousExtraField should not exist',
    );
  });
});
