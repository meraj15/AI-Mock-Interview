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

export function createApp(): Application {
  const app = express();

  // ── Trust proxy (Railway) ─────────────────────────────────────────────────
  // Railway sits behind one reverse-proxy hop. Setting this to 1 allows
  // express-rate-limit to read the real client IP from X-Forwarded-For safely.
  app.set('trust proxy', 1);

  // ── Security headers ─────────────────────────────────────────────────────
  app.use(helmet());

  // ── CORS ─────────────────────────────────────────────────────────────────
  app.use(
    cors({
      origin: config.isDevelopment ? '*' : [],
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
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

  // 404 fallthrough
  app.use((_req: Request, res: Response) => {
    res.status(404).json({ success: false, message: 'Route not found' });
  });

  // ── Centralised error handler ─────────────────────────────────────────────
  app.use(errorHandler);

  return app;
}
