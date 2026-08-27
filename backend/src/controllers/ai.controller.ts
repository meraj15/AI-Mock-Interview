import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { aiService } from '../services/ai.service';

const interviewPlanSchema = z.object({
  role: z.string().min(1, 'role is required').max(100),
  skills: z.array(z.string()).optional().default([]),
  difficulty: z.string().optional().default('Medium'),
  experience: z.string().optional(),
  questionCount: z.number().int().min(1).max(20).optional().default(5),
});

const conversationalTurnSchema = z.object({
  role: z.string().min(1, 'role is required').max(100),
  experience: z.string().optional(),
  skills: z.array(z.string()).optional().default([]),
  currentTopic: z.string().min(1, 'currentTopic is required'),
  topicObjective: z.string().optional().default(''),
  previousQuestion: z.string().min(1, 'previousQuestion is required'),
  candidateAnswer: z.string().default(''),
  conversationSummary: z.string().optional().default(''),
  topicsCovered: z.array(z.string()).optional().default([]),
  topicsRemaining: z.array(z.string()).optional().default([]),
  followUpsUsed: z.number().int().min(0).optional().default(0),
});

const evaluateSessionSchema = z.object({
  role: z.string().min(1, 'role is required').max(100),
  skills: z.array(z.string()).optional().default([]),
  difficulty: z.string().optional().default('Medium'),
  experience: z.string().optional(),
  transcript: z.array(
    z.object({
      question: z.string().min(1),
      answer: z.string().default(''),
      topic: z.string().default('General'),
      type: z.enum(['primary', 'follow_up']).default('primary'),
      timestamp: z.string().optional(),
    })
  ).min(1, 'at least one interview transcript item is required'),
});

export class AIController {
  generateInterviewPlan = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      console.log('[AIController] generateInterviewPlan request body:', JSON.stringify(req.body));
      const validated = interviewPlanSchema.parse(req.body);

      const plan = await aiService.generateInterviewPlan({
        role: validated.role,
        skills: validated.skills,
        difficulty: validated.difficulty,
        experience: validated.experience,
        questionCount: validated.questionCount,
      });

      res.status(200).json({
        success: true,
        data: plan,
      });
    } catch (err) {
      console.error('[AIController] Error in generateInterviewPlan:', err);
      next(err);
    }
  };

  getConversationalTurn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      console.log('[AIController] getConversationalTurn request for topic:', req.body?.currentTopic);
      const validated = conversationalTurnSchema.parse(req.body);

      const turn = await aiService.getNextConversationalTurn({
        role: validated.role,
        currentTopic: validated.currentTopic,
        topicObjective: validated.topicObjective,
        previousQuestion: validated.previousQuestion,
        candidateAnswer: validated.candidateAnswer,
        conversationSummary: validated.conversationSummary,
        topicsRemaining: validated.topicsRemaining,
        followUpsUsed: validated.followUpsUsed,
      });

      res.status(200).json({
        success: true,
        data: turn,
      });
    } catch (err) {
      console.error('[AIController] Error in getConversationalTurn:', err);
      next(err);
    }
  };

  evaluateSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      console.log('[AIController] evaluateSession request for role:', req.body?.role);
      const validated = evaluateSessionSchema.parse(req.body);

      const finalEvaluation = await aiService.generateFinalEvaluation({
        role: validated.role,
        skills: validated.skills,
        difficulty: validated.difficulty,
        experience: validated.experience,
        transcript: validated.transcript,
      });

      res.status(200).json({
        success: true,
        data: finalEvaluation,
      });
    } catch (err) {
      console.error('[AIController] Error in evaluateSession:', err);
      next(err);
    }
  };
}

export const aiController = new AIController();
