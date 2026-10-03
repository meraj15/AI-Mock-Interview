import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { config } from './config';
import { errorHandler } from './middleware/errorHandler';
import { logger } from './utils/logger';
import healthRouter from './routes/health.routes';
import authRouter from './routes/auth.routes';
import profileRouter from './routes/profile.routes';
import resumeRouter from './routes/resume.routes';
import interviewRouter from './routes/interview.routes';
import aiRouter from './routes/ai.routes';
import subscriptionRouter from './routes/subscription.routes';
import webhookRouter from './routes/webhook.routes';
import adminRouter from './routes/admin.routes';
import appRouter from './routes/app.routes';

export function createApp(): Application {
  const app = express();

  // ── Trust proxy (Railway) ─────────────────────────────────────────────────
  // Railway sits behind one reverse-proxy hop. Setting this to 1 allows
  // express-rate-limit to read the real client IP from X-Forwarded-For safely.
  app.set('trust proxy', 1);

  // ── Security headers ─────────────────────────────────────────────────────
  app.use(helmet());

  // ── CORS ─────────────────────────────────────────────────────────────────
  const allowedOrigins = config.cors.allowedOrigins;
  app.use(
    cors({
      origin: (requestOrigin, callback) => {
        // Non-browser / mobile requests (no Origin header) and dev requests are allowed
        if (!requestOrigin || config.isDevelopment) {
          return callback(null, true);
        }
        if (allowedOrigins.length > 0 && allowedOrigins.includes(requestOrigin)) {
          return callback(null, true);
        }
        return callback(new Error(`Origin ${requestOrigin} not allowed by CORS`));
      },
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    })
  );

  // ── Webhook routes (must be BEFORE global JSON body parser) ────────────────
  // The webhook route captures raw body for HMAC signature verification.
  // It uses its own body-reading middleware and must NOT be parsed by express.json().
  app.use('/api/v1/webhooks', webhookRouter);

  // ── Body parsing ─────────────────────────────────────────────────────────
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));

  // ── Request logging (dev) ─────────────────────────────────────────────────
  if (config.isDevelopment) {
    app.use((req: Request, _res: Response, next: NextFunction) => {
      logger.debug(`${req.method} ${req.path}`);
      next();
    });
  }

  // ── Routes ───────────────────────────────────────────────────────────────
  app.use('/health', healthRouter);
  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1/profile', profileRouter);
  app.use('/api/v1/interviews', interviewRouter);
  app.use('/api/v1/ai', aiRouter);
  app.use('/api/resume', resumeRouter);
  app.use('/api/v1/subscriptions', subscriptionRouter);
  app.use('/api/v1/admin', adminRouter);
  app.use('/api/v1/app', appRouter);

  // 404 fallthrough
  app.use((_req: Request, res: Response) => {
    res.status(404).json({ success: false, message: 'Route not found' });
  });

  // ── Centralised error handler ─────────────────────────────────────────────
  app.use(errorHandler);

  return app;
}
