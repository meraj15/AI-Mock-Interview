import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { interviewService } from '../services/interview.service';
import { AuthenticatedRequest } from '../types/auth.types';
import { logger } from '../utils/logger';

// ── Validation schemas ────────────────────────────────────────────────────────

const startSessionSchema = z.object({
  role: z
    .string()
    .min(1, 'role is required')
    .max(120),

  skills: z
    .array(z.string())
    .optional()
    .default([]),

  experience: z
    .string()
    .optional(),

  questionCount: z
    .number()
    .int()
    .min(1)
    .max(20)
    .optional()
    .default(5),
});

const submitAnswerSchema = z.object({
  answer: z
    .string()
    .trim()
    .min(1, 'answer is required'),
});

const saveSessionSchema = z.object({
  role: z
    .string()
    .min(1)
    .max(120),

  type: z
    .string()
    .min(1)
    .max(80)
    .default('technical'),

  // Kept only for backward compatibility with
  // the existing database/repository.
  difficulty: z
    .string()
    .min(1)
    .max(40),

  questionCount: z
    .number()
    .int()
    .min(1)
    .max(50),

  score: z
    .number()
    .int()
    .min(0)
    .max(100),

  hiringBand: z
    .string()
    .min(1)
    .max(60),

  summary: z
    .string()
    .min(1),

  strengths: z
    .array(z.string())
    .max(10)
    .default([]),

  areasToImprove: z
    .array(z.string())
    .max(10)
    .default([]),

  skillScores: z
    .record(z.string(), z.number())
    .default({}),

  durationSecs: z
    .number()
    .int()
    .min(0)
    .default(0),
});

// ── Controller ────────────────────────────────────────────────────────────────

export const interviewController = {
  /**
   * POST /api/v1/interviews/start
   *
   * Start a live conversational interview.
   *
   * Difficulty is NOT provided by the client.
   * The AI adapts question depth based on the candidate's
   * experience and previous answers.
   */
  async startConversationalSession(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const parsed =
        startSessionSchema.parse(req.body);

      const sessionData =
        await interviewService.startConversationalInterview(
          userId,
          parsed
        );

      res.status(201).json({
        success: true,
        data: sessionData,
      });
    } catch (err) {
      logger.error(
        'startConversationalSession error:',
        err
      );

      next(err);
    }
  },

  /**
   * POST /api/v1/interviews/:id/answer
   *
   * Submit candidate answer and get the next
   * adaptive conversational turn.
   */
  async submitAnswer(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const sessionId =
        String(req.params.id);

      const parsed =
        submitAnswerSchema.parse(req.body);

      const turn =
        await interviewService.submitAnswer(
          sessionId,
          userId,
          parsed.answer
        );

      res.status(200).json({
        success: true,
        data: turn,
      });
    } catch (err) {
      logger.error(
        'submitAnswer error:',
        err
      );

      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/:id/result
   *
   * Get final evaluation scorecard and persist
   * the completed interview.
   */
  async getFinalResult(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const sessionId =
        String(req.params.id);

      const result =
        await interviewService.getFinalResult(
          sessionId,
          userId
        );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      logger.error(
        'getFinalResult error:',
        err
      );

      next(err);
    }
  },

  /**
   * POST /api/v1/interviews
   *
   * Save a manually completed interview session.
   */
  async saveSession(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const parsed =
        saveSessionSchema.safeParse(
          req.body
        );

      if (!parsed.success) {
        res.status(422).json({
          success: false,
          message:
            'Invalid interview data.',
          error: {
            details:
              parsed.error.errors,
          },
        });

        return;
      }

      const session =
        await interviewService.saveSession(
          userId,
          parsed.data
        );

      res.status(201).json({
        success: true,
        message:
          'Interview session saved.',
        data: session,
      });
    } catch (err) {
      logger.error(
        'saveSession error:',
        err
      );

      next(err);
    }
  },

  /**
   * GET /api/v1/interviews
   *
   * List authenticated user's sessions.
   */
  async listSessions(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const parsedLimit =
        parseInt(
          String(
            req.query.limit ?? '20'
          ),
          10
        );

      const parsedOffset =
        parseInt(
          String(
            req.query.offset ?? '0'
          ),
          10
        );

      const limit = Number.isNaN(
        parsedLimit
      )
        ? 20
        : Math.min(
            Math.max(parsedLimit, 1),
            100
          );

      const offset = Number.isNaN(
        parsedOffset
      )
        ? 0
        : Math.max(
            parsedOffset,
            0
          );

      const sessions =
        await interviewService.listSessions(
          userId,
          limit,
          offset
        );

      res.json({
        success: true,
        data: sessions,
      });
    } catch (err) {
      logger.error(
        'listSessions error:',
        err
      );

      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/stats
   *
   * Aggregated performance statistics.
   */
  async getStats(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const stats =
        await interviewService.getStats(
          userId
        );

      res.json({
        success: true,
        data: stats,
      });
    } catch (err) {
      logger.error(
        'getStats error:',
        err
      );

      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/:id
   *
   * Get a single interview session.
   */
  async getSession(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;

      const sessionId =
        String(req.params.id);

      const session =
        await interviewService.getSession(
          sessionId,
          userId
        );

      res.json({
        success: true,
        data: session,
      });
    } catch (err) {
      logger.error(
        'getSession error:',
        err
      );

      next(err);
    }
  },
};