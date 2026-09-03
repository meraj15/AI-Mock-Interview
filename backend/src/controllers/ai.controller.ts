import {
  Request,
  Response,
  NextFunction,
} from 'express';
import { z } from 'zod';
import { aiService } from '../services/ai.service';

// ============================================================
// VALIDATION SCHEMAS
// ============================================================

/**
 * Generate the first interview question.
 *
 * Difficulty is intentionally NOT included.
 * The AI determines the appropriate depth dynamically
 * from experience and the candidate's answers.
 */
const interviewPlanSchema = z.object({
  role: z
    .string()
    .min(1, 'role is required')
    .max(100),

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

/**
 * Generate the next conversational interview turn.
 *
 * Difficulty is NOT sent by the client.
 * The AI adapts automatically based on the candidate's
 * previous answer and demonstrated knowledge.
 */
const conversationalTurnSchema = z.object({
  role: z
    .string()
    .min(1, 'role is required')
    .max(100),

  experience: z
    .string()
    .optional(),

  skills: z
    .array(z.string())
    .optional()
    .default([]),

  currentTopic: z
    .string()
    .min(1, 'currentTopic is required'),

  topicObjective: z
    .string()
    .optional()
    .default(''),

  previousQuestion: z
    .string()
    .min(1, 'previousQuestion is required'),

  candidateAnswer: z
    .string()
    .trim()
    .min(1, 'candidateAnswer is required'),

  conversationSummary: z
    .string()
    .optional()
    .default(''),

  topicsCovered: z
    .array(z.string())
    .optional()
    .default([]),

  topicsRemaining: z
    .array(z.string())
    .optional()
    .default([]),

  followUpsUsed: z
    .number()
    .int()
    .min(0)
    .optional()
    .default(0),

  recentQuestions: z
    .array(z.string())
    .optional()
    .default([]),

  turnNumber: z
    .number()
    .int()
    .min(1)
    .optional(),

  maxTurns: z
    .number()
    .int()
    .min(1)
    .optional(),
});

/**
 * Final interview evaluation.
 *
 * Difficulty is intentionally NOT included.
 * Evaluation is based on what the candidate actually
 * demonstrated during the interview.
 */
const evaluateSessionSchema = z.object({
  role: z
    .string()
    .min(1, 'role is required')
    .max(100),

  skills: z
    .array(z.string())
    .optional()
    .default([]),

  experience: z
    .string()
    .optional(),

  transcript: z
    .array(
      z.object({
        question: z
          .string()
          .min(1),

        answer: z
          .string()
          .default(''),

        topic: z
          .string()
          .default('General'),

        type: z
          .enum([
            'primary',
            'follow_up',
          ])
          .default('primary'),

        timestamp: z
          .string()
          .optional(),
      }),
    )
    .min(
      1,
      'at least one interview transcript item is required',
    ),
});

// ============================================================
// CONTROLLER
// ============================================================

export class AIController {

  /**
   * POST /ai/interview-plan
   *
   * Generates the first interview question.
   */
  generateInterviewPlan = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      console.log(
        '[AIController] generateInterviewPlan request body:',
        JSON.stringify(req.body),
      );

      const validated =
        interviewPlanSchema.parse(
          req.body,
        );

      const plan =
        await aiService.generateInterviewPlan({
          role: validated.role,
          skills: validated.skills,
          experience:
            validated.experience,
          questionCount:
            validated.questionCount,
        });

      res.status(200).json({
        success: true,
        data: plan,
      });
    } catch (err) {
      console.error(
        '[AIController] Error in generateInterviewPlan:',
        err,
      );

      next(err);
    }
  };

  /**
   * POST /ai/conversational-turn
   *
   * Generates the next adaptive interview question.
   */
  getConversationalTurn = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      console.log(
        '[AIController] getConversationalTurn request:',
        {
          topic:
            req.body?.currentTopic,
          turn:
            req.body?.turnNumber,
        },
      );

      const validated =
        conversationalTurnSchema.parse(
          req.body,
        );

      const turn =
        await aiService.getNextConversationalTurn({
          role: validated.role,

          experience:
            validated.experience,

          skills:
            validated.skills,

          currentTopic:
            validated.currentTopic,

          topicObjective:
            validated.topicObjective,

          previousQuestion:
            validated.previousQuestion,

          candidateAnswer:
            validated.candidateAnswer,

          conversationSummary:
            validated.conversationSummary,

          topicsCovered:
            validated.topicsCovered,

          topicsRemaining:
            validated.topicsRemaining,

          followUpsUsed:
            validated.followUpsUsed,

          recentQuestions:
            validated.recentQuestions,

          turnNumber:
            validated.turnNumber,

          maxTurns:
            validated.maxTurns,
        });

      res.status(200).json({
        success: true,
        data: turn,
      });
    } catch (err) {
      console.error(
        '[AIController] Error in getConversationalTurn:',
        err,
      );

      next(err);
    }
  };

  /**
   * POST /ai/evaluate-session
   *
   * Generates the final interview evaluation.
   */
  evaluateSession = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      console.log(
        '[AIController] evaluateSession request for role:',
        req.body?.role,
      );

      const validated =
        evaluateSessionSchema.parse(
          req.body,
        );

      const finalEvaluation =
        await aiService.generateFinalEvaluation({
          role: validated.role,

          skills:
            validated.skills,

          experience:
            validated.experience,

          transcript:
            validated.transcript,
        });

      res.status(200).json({
        success: true,
        data: finalEvaluation,
      });
    } catch (err) {
      console.error(
        '[AIController] Error in evaluateSession:',
        err,
      );

      next(err);
    }
  };
}

// ============================================================
// SINGLETON
// ============================================================

export const aiController =
  new AIController();
