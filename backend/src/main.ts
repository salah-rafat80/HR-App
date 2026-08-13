import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import * as express from 'express';
import { AppModule } from './app.module';

export async function bootstrap() {
  const isProduction = process.env.NODE_ENV === 'production';
  const rawOrigins = process.env.CORS_ALLOWED_ORIGINS || '';
  const allowedOrigins = rawOrigins
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  if (isProduction) {
    if (allowedOrigins.length === 0 || allowedOrigins.includes('*')) {
      throw new Error(
        'FATAL: CORS_ALLOWED_ORIGINS must be explicitly configured in production and cannot be empty or contain "*"',
      );
    }
  }

  // Create Nest app with default body parser disabled to enforce 100kb limit
  const app = await NestFactory.create(AppModule, { bodyParser: false });

  // Security Headers & Hardening
  app.use(helmet());

  // Disable x-powered-by header
  const httpAdapter = app.getHttpAdapter();
  if (httpAdapter) {
    const expressApp = httpAdapter.getInstance() as {
      disable?: (setting: string) => void;
    };
    if (expressApp && typeof expressApp.disable === 'function') {
      expressApp.disable('x-powered-by');
    }
  }

  // Explicit Request Body Size Limits (100kb max)
  app.use(express.json({ limit: '100kb' }));
  app.use(express.urlencoded({ extended: true, limit: '100kb' }));

  // Strict Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Strict CORS Configuration with Explicit Origin Callback
  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      if (!origin) {
        // Allow requests with no origin (mobile app, server-to-server)
        return callback(null, true);
      }
      if (
        allowedOrigins.includes(origin) ||
        (!isProduction && allowedOrigins.includes('*'))
      ) {
        return callback(null, true);
      }
      return callback(
        new Error(`CORS policy forbidden for origin: ${origin}`),
        false,
      );
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  return app;
}

void bootstrap();
