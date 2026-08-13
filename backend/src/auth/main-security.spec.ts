import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, Controller, Post, Body, Get } from '@nestjs/common';
import request from 'supertest';
import helmet from 'helmet';
import * as express from 'express';
import { IsNotEmpty, IsString } from 'class-validator';

class SampleDto {
  @IsNotEmpty()
  @IsString()
  data!: string;
}

@Controller('security-test')
class SecurityTestController {
  @Get('ping')
  ping() {
    return { status: 'ok' };
  }

  @Post('validate')
  validate(@Body() dto: SampleDto) {
    return dto;
  }
}

describe('Real Application Security & Configuration Suite', () => {
  let app: INestApplication;
  const allowedOrigin = 'https://trusted.hr-app.com';

  beforeAll(async () => {
    process.env.CORS_ALLOWED_ORIGINS = allowedOrigin;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [SecurityTestController],
    }).compile();

    // Instantiate Nest app with bodyParser: false matching main.ts
    app = moduleFixture.createNestApplication({ bodyParser: false });

    // Apply main.ts configuration
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

    // Explicit 100kb body limit
    app.use(express.json({ limit: '100kb' }));
    app.use(express.urlencoded({ extended: true, limit: '100kb' }));

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    app.enableCors({
      origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
        if (!origin || origin === allowedOrigin) {
          return callback(null, true);
        }
        return callback(new Error(`CORS policy forbidden for origin: ${origin}`), false);
      },
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    });

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. Helmet headers set & x-powered-by header disabled', async () => {
    const res = await request(app.getHttpServer()).get('/security-test/ping');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('2. Allowed origin gets CORS permission', async () => {
    const res = await request(app.getHttpServer())
      .get('/security-test/ping')
      .set('Origin', allowedOrigin);

    expect(res.headers['access-control-allow-origin']).toBe(allowedOrigin);
    expect(res.headers['access-control-allow-credentials']).toBe('true');
  });

  it('3. Unallowed origin is denied CORS permission', async () => {
    const res = await request(app.getHttpServer())
      .get('/security-test/ping')
      .set('Origin', 'https://malicious-attacker.com');

    expect(res.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('4. Request payload > 100KB is rejected with 413 Payload Too Large', async () => {
    const oversizedPayload = { data: 'A'.repeat(105 * 1024) }; // 105 KB
    const res = await request(app.getHttpServer())
      .post('/security-test/validate')
      .send(oversizedPayload);

    expect(res.status).toBe(413);
  });

  it('5. Request with unknown DTO field is rejected with 400 Bad Request', async () => {
    const res = await request(app.getHttpServer())
      .post('/security-test/validate')
      .send({
        data: 'validString',
        unknownField: 'illegalPayload',
      });

    expect(res.status).toBe(400);
    expect(JSON.stringify(res.body)).toContain('property unknownField should not exist');
  });
});
