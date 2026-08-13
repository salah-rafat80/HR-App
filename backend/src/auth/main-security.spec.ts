import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import helmet from 'helmet';
import * as express from 'express';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';

describe('Real Application Security & Bootstrap Configuration Suite', () => {
  let app: INestApplication;
  const allowedOrigin = 'https://trusted.hr-app.com';

  const mockPrisma = {
    user: {
      findUnique: jest.fn().mockImplementation(({ where }) => {
        if (where.employeeCode === 'EMP-001') {
          return Promise.resolve({
            id: 'user-uuid-1234',
            employeeCode: 'EMP-001',
            email: 'employee@company.com',
            password:
              '$2b$10$e8w8mX8hJ.1zX8zX8zX8zO1zX8zX8zX8zX8zX8zX8zX8zX8zX8zX8',
            name: 'John Doe',
            role: 'employee',
            isActive: true,
          });
        }
        return Promise.resolve(null);
      }),
      update: jest.fn().mockResolvedValue({ id: 'user-uuid-1234' }),
    },
  };

  beforeAll(async () => {
    process.env.CORS_ALLOWED_ORIGINS = allowedOrigin;
    process.env.JWT_SECRET =
      'test-jwt-secret-min-32-characters-required-for-security-tests';

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .compile();

    // Create app with bodyParser: false matching main.ts
    app = moduleFixture.createNestApplication({ bodyParser: false });

    // Apply exact main.ts configuration
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

    const allowedOrigins = [allowedOrigin];
    app.enableCors({
      origin: (
        origin: string | undefined,
        callback: (err: Error | null, allow?: boolean) => void,
      ) => {
        if (!origin || allowedOrigins.includes(origin)) {
          return callback(null, true);
        }
        return callback(null, false);
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
    const res = await request(app.getHttpServer()).get('/auth/login');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['x-content-type-options']).toBe('nosniff');
  });

  it('2. Allowed origin receives CORS permission header', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .set('Origin', allowedOrigin)
      .send({ employeeCode: 'EMP-001', password: 'Password123!' });

    expect(res.headers['access-control-allow-origin']).toBe(allowedOrigin);
    expect(res.headers['access-control-allow-credentials']).toBe('true');
  });

  it('3. Unallowed origin gets standard non-500 response without CORS header', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .set('Origin', 'https://untrusted-hacker.com')
      .send({ employeeCode: 'EMP-001', password: 'Password123!' });

    expect(res.status).not.toBe(500);
    expect(res.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('4. Request payload > 100KB is rejected with 413 Payload Too Large', async () => {
    const oversizedPayload = {
      employeeCode: 'EMP-001',
      password: 'A'.repeat(105 * 1024),
    };
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send(oversizedPayload);

    expect(res.status).toBe(413);
  });

  it('5. Request with unknown DTO field is rejected with 400 Bad Request', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        employeeCode: 'EMP-001',
        password: 'Password123!',
        unsupportedExtraParam: 'hackedPayload',
      });

    expect(res.status).toBe(400);
    expect(JSON.stringify(res.body)).toContain(
      'property unsupportedExtraParam should not exist',
    );
  });
});
