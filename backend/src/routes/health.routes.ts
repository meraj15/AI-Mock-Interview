import { Router, Request, Response } from 'express';

const router = Router();

/**
 * GET /health
 * Health check — returns 200 when the API is running.
 */
router.get('/', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'API is running',
    timestamp: new Date().toISOString(),
  });
});

export default router;
