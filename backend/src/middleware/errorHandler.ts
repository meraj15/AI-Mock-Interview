import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors/AppError';
import { logger } from '../utils/logger';
import { config } from '../config';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Zod validation errors
  if (err instanceof ZodError) {
    res.status(422).json({
      success: false,
      message: 'Validation failed',
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request payload',
        details: err.errors.map((e) => ({ field: e.path.join('.'), message: e.message })),
      },
    });
    return;
  }

  // Operational app errors
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error(`[AppError] ${err.message}`, { stack: err.stack });
    }
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      error: {
        code: err.errorCode,
        message: err.message,
      },
    });
    return;
  }

  // Unknown internal server errors
  const message = err instanceof Error ? err.message : 'Internal server error';
  logger.error(`[UnhandledError] ${message}`, { err });

  res.status(500).json({
    success: false,
    message: config.isDevelopment ? message : 'Internal server error',
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: config.isDevelopment ? message : 'An unexpected error occurred',
    },
  });
}
