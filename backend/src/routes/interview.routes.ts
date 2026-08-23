import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { interviewController } from '../controllers/interview.controller';

const router = Router();

// All interview routes require a valid JWT
router.use(authMiddleware);

// ── Stats (must be before /:id to avoid shadowing) ───────────────────────────
// GET /api/v1/interviews/stats
router.get('/stats', interviewController.getStats);

// ── Session CRUD ─────────────────────────────────────────────────────────────
// POST /api/v1/interviews
router.post('/', interviewController.saveSession);

// GET /api/v1/interviews
router.get('/', interviewController.listSessions);

// GET /api/v1/interviews/:id
router.get('/:id', interviewController.getSession);

export default router;
