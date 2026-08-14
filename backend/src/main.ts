import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import * as express from 'express';
import type { Request, Response, NextFunction } from 'express';
import { AppModule } from './app.module';

export async function bootstrap() {
  const isProduction = process.env.NODE_ENV === 'production';
  const rawOrigins = process.env.CORS_ALLOWED_ORIGINS || '';
  const allowedOrigins = rawOrigins
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  if (isProduction && allowedOrigins.includes('*')) {
    throw new Error(
      'FATAL: CORS_ALLOWED_ORIGINS cannot contain "*" in production',
    );
  }

  // A native mobile client sends no Origin header. When no web client is deployed,
  // production starts with an empty browser allowlist and permits only no-origin requests.
  // Add the exact web origins to CORS_ALLOWED_ORIGINS before deploying Flutter Web.

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

  // Convert body-parser's PayloadTooLargeError (err.status=413) to a clean HTTP 413 response.
  // NestJS BaseExceptionFilter treats non-HttpException errors as 500; this middleware intercepts first.
  app.use(
    (
      err: { status?: number },
      _req: Request,
      res: Response,
      next: NextFunction,
    ) => {
      if (err?.status === 413) {
        res.status(413).json({ statusCode: 413, message: 'Payload Too Large' });
        return;
      }
      next(err);
    },
  );

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
      return callback(null, false);
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
