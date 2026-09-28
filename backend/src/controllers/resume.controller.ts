import { Request, Response, NextFunction } from 'express';
import { resumeService } from '../services/resume.service';
import { entitlementService } from '../services/entitlement.service';
import { logger } from '../utils/logger';

export const resumeController = {
  /**
   * POST /api/resume/parse
   * Expects: multipart/form-data with field "file" (PDF / DOC / TXT)
   * Returns: { success: true, profile: ResumeProfile }
   * Enforces server-side resume scan quota (Free: 1 scan, Pro: 5 scans per billing period)
   */
  async parseResume(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        res.status(400).json({
          success: false,
          message: 'No file uploaded. Please attach a resume file with field name "file".',
        });
        return;
      }

      const userId = (req as any).user?.id;
      if (userId) {
        const entitlement = await entitlementService.getUserEntitlement(userId);
        if (entitlement.resumeScansRemaining <= 0) {
          logger.warn(`[PAYWALL] Resume scan quota exhausted: userId=${userId} tier=${entitlement.tier} used=${entitlement.resumeScansUsed}/${entitlement.maxResumeScans}`);
          res.status(403).json({
            success: false,
            code: 'QUOTA_EXHAUSTED',
            feature: 'RESUME_SCAN',
            currentTier: entitlement.tier,
            limit: entitlement.maxResumeScans,
            used: entitlement.resumeScansUsed,
            message: `You have reached your limit of ${entitlement.maxResumeScans} resume scan${entitlement.maxResumeScans === 1 ? '' : 's'} for this period. Upgrade to Pro for up to 5 scans!`,
          });
          return;
        }
      }

      const { buffer, originalname, size } = req.file;

      logger.info(`Resume parse request: ${originalname} (${(size / 1024).toFixed(1)} KB)`);

      if (size > 10 * 1024 * 1024) {
        res.status(400).json({
          success: false,
          message: 'File too large. Maximum size is 10 MB.',
        });
        return;
      }

      const profile = await resumeService.parseResume(buffer, originalname);

      if (userId) {
        await entitlementService.consumeResumeScanQuota(userId);
      }

      res.status(200).json({
        success: true,
        profile,
      });
    } catch (error) {
      logger.error('Resume parse failed:', error);
      next(error);
    }
  },
};
