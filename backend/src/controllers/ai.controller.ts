import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { aiService } from '../services/ai.service';

const generateQuestionsSchema = z.object({
  role: z.string().min(1, 'role is required').max(100),
  skills: z.array(z.string()).min(1, 'at least one skill is required').max(30),
  difficulty: z.enum(['Easy', 'Medium', 'Hard', 'Adaptive']).default('Medium'),
  questionCount: z.number().int().min(1).max(20).default(5),
  experience: z.string().optional(),
});

export class AIController {
  generateQuestions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      console.log('[AIController] generateQuestions request body:', JSON.stringify(req.body));
      const validated = generateQuestionsSchema.parse(req.body);

      const questions = await aiService.generateInterviewQuestions({
        role: validated.role,
        skills: validated.skills,
        difficulty: validated.difficulty,
        questionCount: validated.questionCount,
        experience: validated.experience,
      });

      console.log(`[AIController] Successfully generated ${questions.length} questions.`);
      questions.forEach((q, idx) => {
        console.log(`  [AIController] Q${idx + 1}: ${q.primaryQuestion}`);
      });

      res.status(200).json({
        success: true,
        data: { questions },
      });
    } catch (err) {
      console.error('[AIController] Error in generateQuestions:', err);
      next(err);
    }
  };
}

export const aiController = new AIController();
