import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { interviewService } from '../services/interview.service';
import { entitlementService, FREE_LIMITS } from '../services/entitlement.service';
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
    .default(10),

  mode: z
    .string()
    .optional(),

  focusArea: z
    .union([z.string(), z.array(z.string())])
    .optional(),

  enableVoiceMode: z
    .boolean()
    .optional()
    .default(false),

  aiPersona: z
    .string()
    .optional(),

  idempotencyKey: z
    .string()
    .optional(),
});

const submitAnswerSchema = z.object({
  answer: z
    .string()
    .trim()
    .min(1, 'answer is required')
    .max(3000, 'Answer must be 3000 characters or fewer'),
  answerId: z
    .string()
    .trim()
    .optional(),
  turnNumber: z
    .number()
    .int()
    .optional(),
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

// ── Idempotency Caches for Session Starts ──────────────────────────────────────
const inFlightStarts = new Map<string, Promise<any>>();
const recentStarts = new Map<string, { result: any; timestamp: number }>();

function cleanOldStarts(): void {
  const cutoff = Date.now() - 30000; // 30 seconds TTL
  for (const [key, value] of recentStarts.entries()) {
    if (value.timestamp < cutoff) {
      recentStarts.delete(key);
    }
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

export const interviewController = {
  /**
   * POST /api/v1/interviews/start
   *
   * Start a live conversational interview.
   * Enforces server-side quota, tier limits (voice, personas, deep dive),
   * and safe idempotent reservation.
   */
  async startConversationalSession(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const parsed = startSessionSchema.parse(req.body);

      // Clean stale idempotency keys
      cleanOldStarts();

      // Idempotency composite key
      const idempotencyKey = parsed.idempotencyKey
        ? `${userId}:${parsed.idempotencyKey}`
        : `${userId}:${parsed.role}:${parsed.questionCount}:${parsed.mode || 'default'}`;

      // If already started recently (e.g. rapid double tap / retry), return existing without double-counting quota
      const cached = recentStarts.get(idempotencyKey);
      if (cached) {
        logger.info(`[InterviewController] Returning idempotent cached session for key=${idempotencyKey}`);
        res.status(200).json({
          success: true,
          data: cached.result,
        });
        return;
      }

      // If already in flight, coalesce
      if (inFlightStarts.has(idempotencyKey)) {
        logger.info(`[InterviewController] Coalescing in-flight session start for key=${idempotencyKey}`);
        const result = await inFlightStarts.get(idempotencyKey);
        res.status(201).json({
          success: true,
          data: result,
        });
        return;
      }

      // 1. Resolve user entitlement and verify quota
      const entitlement = await entitlementService.getUserEntitlement(userId);

      if (entitlement.interviewsRemaining <= 0) {
        logger.warn(`[PAYWALL] Quota exhausted: userId=${userId} tier=${entitlement.tier} used=${entitlement.interviewsUsed}/${entitlement.interviewsLimit}`);
        res.status(403).json({
          success: false,
          code: 'QUOTA_EXHAUSTED',
          feature: 'INTERVIEW',
          currentTier: entitlement.tier,
          limit: entitlement.interviewsLimit,
          used: entitlement.interviewsUsed,
          message: 'You have reached your interview limit for this billing period. Upgrade to Pro for 30 interviews/month!',
        });
        return;
      }

      // 2. Enforce mode restrictions (Deep Dive is PRO only)
      if (parsed.mode?.toLowerCase() === 'deep' && !entitlement.canUseDeepDive) {
        logger.warn(`[PAYWALL] Deep dive locked: userId=${userId} tier=${entitlement.tier}`);
        res.status(403).json({
          success: false,
          code: 'FEATURE_LOCKED',
          feature: 'DEEP_DIVE_INTERVIEW',
          currentTier: entitlement.tier,
          requiredTier: 'PRO',
          message: 'Deep Dive interview mode is available on Pro.',
        });
        return;
      }

      // 3. Enforce voice mode restrictions
      if (parsed.enableVoiceMode && !entitlement.canUseVoice) {
        logger.warn(`[PAYWALL] Voice locked: userId=${userId} tier=${entitlement.tier}`);
        res.status(403).json({
          success: false,
          code: 'FEATURE_LOCKED',
          feature: 'VOICE',
          currentTier: entitlement.tier,
          requiredTier: 'PRO',
          message: 'Full voice interviews are available on Pro.',
        });
        return;
      }

      // 4. Enforce persona restrictions
      if (
        parsed.aiPersona &&
        parsed.aiPersona !== FREE_LIMITS.standardPersona &&
        !entitlement.canUseAdvancedPersonas
      ) {
        logger.warn(`[PAYWALL] Persona locked: userId=${userId} persona=${parsed.aiPersona} tier=${entitlement.tier}`);
        res.status(403).json({
          success: false,
          code: 'FEATURE_LOCKED',
          feature: 'ADVANCED_PERSONA',
          currentTier: entitlement.tier,
          requiredTier: 'PRO',
          message: 'Advanced interviewer personas are available on Pro.',
        });
        return;
      }

      // 5. Enforce question count limit (Free: max 5, Pro: max 12)
      const clampedQuestionCount = Math.min(
        parsed.questionCount ?? 10,
        entitlement.maxQuestionsPerSession
      );

      // 6. Execute session start with coalescing
      const startPromise = interviewService.startConversationalInterview(userId, {
        ...parsed,
        questionCount: clampedQuestionCount,
      });

      inFlightStarts.set(idempotencyKey, startPromise);

      let sessionData;
      try {
        sessionData = await startPromise;
      } finally {
        inFlightStarts.delete(idempotencyKey);
      }

      // 7. Store in recent starts cache for idempotency
      recentStarts.set(idempotencyKey, {
        result: sessionData,
        timestamp: Date.now(),
      });

      // 8. Safely consume quota after successful creation
      await entitlementService.consumeInterviewQuota(userId);

      res.status(201).json({
        success: true,
        data: sessionData,
      });
    } catch (err) {
      logger.error('startConversationalSession error:', err);
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
      const sessionId = String(req.params.id);
      const parsed = submitAnswerSchema.parse(req.body);

      const turn = await interviewService.submitAnswer(
        sessionId,
        userId,
        parsed.answer,
        parsed.answerId,
        parsed.turnNumber
      );

      res.status(200).json({
        success: true,
        data: turn,
      });
    } catch (err) {
      logger.error('submitAnswer error:', err);
      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/:id/result
   *
   * Get final evaluation scorecard and persist the completed interview.
   * Gated fields are selectively sanitized for Free users without extra AI calls.
   */
  async getFinalResult(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const sessionId = String(req.params.id);

      const result = await interviewService.getFinalResult(sessionId, userId);
      const entitlement = await entitlementService.getUserEntitlement(userId);

      if (entitlement.tier === 'FREE') {
        const gatedResult = {
          ...result,
          strengths: (result.strengths || []).slice(0, 1),
          areasToImprove: (result.areasToImprove || []).slice(0, 1),
          // First question expected answer shown, subsequent questions require Pro
          questionReviews: (result.questionReviews || []).map((q, idx) => ({
            ...q,
            expectedAnswer:
              idx === 0
                ? q.expectedAnswer
                : 'Upgrade to Pro to view comprehensive expected answers and STAR framework guidance.',
          })),
          recommendations: (result.recommendations || []).slice(0, 1),
          isGated: true,
        };

        res.status(200).json({
          success: true,
          data: gatedResult,
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err) {
      logger.error('getFinalResult error:', err);
      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/:id/pdf
   *
   * Generate/download assessment report PDF data.
   * Available exclusively to PRO users.
   */
  async exportPdf(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const sessionId = String(req.params.id);
      const entitlement = await entitlementService.getUserEntitlement(userId);

      if (!entitlement.canExportPdf) {
        logger.warn(`[PAYWALL] PDF report locked for userId=${userId} tier=${entitlement.tier}`);
        res.status(403).json({
          success: false,
          code: 'FEATURE_LOCKED',
          feature: 'PDF_REPORT',
          currentTier: entitlement.tier,
          requiredTier: 'PRO',
          message: 'PDF Assessment reports are exclusive to the Pro Plan.',
        });
        return;
      }

      const session = await interviewService.getSession(sessionId, userId);
      res.status(200).json({
        success: true,
        message: 'PDF report generated successfully',
        data: {
          sessionId: session.id,
          role: session.role,
          score: session.score,
          hiringBand: session.hiringBand,
          summary: session.summary,
          strengths: session.strengths,
          areasToImprove: session.areasToImprove,
          questions: session.questions,
          durationSecs: session.durationSecs,
          createdAt: session.createdAt,
        },
      });
    } catch (err) {
      logger.error('exportPdf error:', err);
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
      const parsed = saveSessionSchema.safeParse(req.body);

      if (!parsed.success) {
        res.status(422).json({
          success: false,
          message: 'Invalid interview data.',
          error: {
            details: parsed.error.errors,
          },
        });
        return;
      }

      const session = await interviewService.saveSession(userId, parsed.data);

      res.status(201).json({
        success: true,
        message: 'Interview session saved.',
        data: session,
      });
    } catch (err) {
      logger.error('saveSession error:', err);
      next(err);
    }
  },

  /**
   * GET /api/v1/interviews
   *
   * List authenticated user's sessions.
   * Free users are limited to their 3 most recent sessions.
   */
  async listSessions(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const entitlement = await entitlementService.getUserEntitlement(userId);

      const parsedLimit = parseInt(String(req.query.limit ?? '20'), 10);
      const parsedOffset = parseInt(String(req.query.offset ?? '0'), 10);

      let limit = Number.isNaN(parsedLimit)
        ? 20
        : Math.min(Math.max(parsedLimit, 1), 100);

      let offset = Number.isNaN(parsedOffset)
        ? 0
        : Math.max(parsedOffset, 0);

      // Free tier: only last 3 sessions accessible
      if (entitlement.tier === 'FREE') {
        limit = Math.min(limit, FREE_LIMITS.historySessionLimit);
        offset = 0;
      }

      const sessions = await interviewService.listSessions(userId, limit, offset);

      res.json({
        success: true,
        data: sessions,
        meta: {
          tier: entitlement.tier,
          isCapped: entitlement.tier === 'FREE',
          maxVisible: entitlement.tier === 'FREE' ? FREE_LIMITS.historySessionLimit : null,
        },
      });
    } catch (err) {
      logger.error('listSessions error:', err);
      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/stats
   *
   * Aggregated performance statistics.
   * Free tier is restricted to 7-day trend.
   */
  async getStats(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const entitlement = await entitlementService.getUserEntitlement(userId);

      const rawDays = req.query.days as string | undefined;
      const days = rawDays ? parseInt(rawDays, 10) : undefined;
      let validDays = days && !isNaN(days) && days > 0 ? days : undefined;

      // Free tier gets 7-day trend only
      if (entitlement.tier === 'FREE') {
        validDays = 7;
      }

      const stats = await interviewService.getStats(userId, validDays);

      res.json({
        success: true,
        data: stats,
        meta: {
          tier: entitlement.tier,
          requestedDays: validDays,
        },
      });
    } catch (err) {
      logger.error('getStats error:', err);
      next(err);
    }
  },

  /**
   * GET /api/v1/interviews/:id
   *
   * Get a single interview session.
   * Free users cannot access sessions older than their 3 most recent.
   */
  async getSession(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.user!.id;
      const sessionId = String(req.params.id);
      const entitlement = await entitlementService.getUserEntitlement(userId);

      if (entitlement.tier === 'FREE') {
        const recentSessions = await interviewService.listSessions(
          userId,
          FREE_LIMITS.historySessionLimit,
          0
        );
        const isRecent = recentSessions.some((s) => s.id === sessionId);
        if (!isRecent) {
          logger.warn(`[PAYWALL] Historical session archive locked for userId=${userId} sessionId=${sessionId}`);
          res.status(403).json({
            success: false,
            code: 'FEATURE_LOCKED',
            feature: 'HISTORICAL_ARCHIVE',
            currentTier: 'FREE',
            requiredTier: 'PRO',
            message: 'Access to historical sessions beyond your 3 most recent requires Pro.',
          });
          return;
        }
      }

      const session = await interviewService.getSession(sessionId, userId);

      res.json({
        success: true,
        data: session,
      });
    } catch (err) {
      logger.error('getSession error:', err);
      next(err);
    }
  },
};