import { Router, Request, Response, NextFunction } from 'express';
import { adminAppUpdatesService } from '../services/admin/admin.app-updates.service';

const router = Router();

/**
 * Public Endpoint: GET /api/v1/app/version
 * 
 * Accessible without authentication (supports pre-login version checks).
 * Returns only published, sanitized update metadata for the requested platform.
 * Strips all internal admin data, IDs, secrets, and internal timestamps.
 */
router.get('/version', async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const platform = (req.query.platform as string) || (req.headers['x-platform'] as string) || 'android';
    const update = await adminAppUpdatesService.getPublishedUpdateForPlatform(platform);

    res.status(200).json({
      success: true,
      data: update,
      message: update ? 'Update configuration retrieved successfully' : 'No published update available',
    });
  } catch (err) {
    next(err);
  }
});

export default router;
