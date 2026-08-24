import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { aiController } from '../controllers/ai.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Limit question generation: 30 requests per minute per user
const aiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests, please try again in a minute.',
  },
});

// POST /api/v1/ai/questions — Generate interview questions via Gemini
router.post('/questions', authMiddleware, aiLimiter, aiController.generateQuestions);

export default router;
