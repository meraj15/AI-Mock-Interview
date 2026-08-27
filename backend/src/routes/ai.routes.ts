import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { aiController } from '../controllers/ai.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// Limit AI requests: 30 requests per minute per user
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

// POST /api/v1/ai/interview-plan — Generate blueprint + opening question via Gemini
router.post('/interview-plan', authMiddleware, aiLimiter, aiController.generateInterviewPlan);

// POST /api/v1/ai/conversational-turn — Generate next natural conversational turn via Gemini
router.post('/conversational-turn', authMiddleware, aiLimiter, aiController.getConversationalTurn);

// POST /api/v1/ai/evaluate-session — Generate final interview scorecard & evaluation via Gemini
router.post('/evaluate-session', authMiddleware, aiLimiter, aiController.evaluateSession);

export default router;
