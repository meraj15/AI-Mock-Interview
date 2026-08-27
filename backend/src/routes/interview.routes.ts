import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { interviewController } from '../controllers/interview.controller';

const router = Router();

// All interview routes require a valid JWT
router.use(authMiddleware);

// ── Conversational Interview Lifecycle ───────────────────────────────────────
// POST /api/v1/interviews/start — Generate blueprint + first question
router.post('/start', interviewController.startConversationalSession);

// POST /api/v1/interviews/:id/answer — Submit answer & get next conversational turn
router.post('/:id/answer', interviewController.submitAnswer);

// GET /api/v1/interviews/:id/result — Get final evaluation scorecard (saves to DB)
router.get('/:id/result', interviewController.getFinalResult);

// ── Stats (must be before /:id to avoid shadowing) ───────────────────────────
// GET /api/v1/interviews/stats
router.get('/stats', interviewController.getStats);

// ── Session CRUD ─────────────────────────────────────────────────────────────
// POST /api/v1/interviews — Manual session save
router.post('/', interviewController.saveSession);

// GET /api/v1/interviews — List historical sessions
router.get('/', interviewController.listSessions);

// GET /api/v1/interviews/:id — Get session by ID
router.get('/:id', interviewController.getSession);

export default router;
