import { Request, Response, NextFunction } from 'express';
import { resumeService } from '../services/resume.service';
import { entitlementService } from '../services/entitlement.service';
import { telemetryService } from '../services/telemetry.service';
import { logger } from '../utils/logger';

export const resumeController = {
  /**
   * POST /api/resume/parse
   * Expects: multipart/form-data with field "file" (PDF / DOC / TXT)
   * Returns: { success: true, profile: ResumeProfile }
   * Enforces server-side resume scan quota (Free: 1 scan, Pro: 5 scans per billing period)
   */
  async parseResume(req: Request, res: Response, next: NextFunction): Promise<void> {
    const startTime = Date.now();
    const userId = (req as any).user?.id;
    const file = req.file;

    try {
      if (!file) {
        telemetryService.recordResumeParse({
          userId,
          fileName: 'unknown',
          fileSize: 0,
          status: 'FAILED',
          errorReason: 'NO_FILE_UPLOADED',
          durationMs: Date.now() - startTime,
        }).catch(() => {});

        res.status(400).json({
          success: false,
          message: 'No file uploaded. Please attach a resume file with field name "file".',
        });
        return;
      }

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

      const { buffer, originalname, size } = file;

      logger.info(`Resume parse request: ${originalname} (${(size / 1024).toFixed(1)} KB)`);

      if (size > 10 * 1024 * 1024) {
        telemetryService.recordResumeParse({
          userId,
          fileName: originalname,
          fileSize: size,
          status: 'FAILED',
          errorReason: 'FILE_TOO_LARGE',
          durationMs: Date.now() - startTime,
        }).catch(() => {});

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

      telemetryService.recordResumeParse({
        userId,
        fileName: originalname,
        fileSize: size,
        status: 'SUCCESS',
        durationMs: Date.now() - startTime,
      }).catch(() => {});

      res.status(200).json({
        success: true,
        profile,
      });
    } catch (error: any) {
      if (file) {
        telemetryService.recordResumeParse({
          userId,
          fileName: file.originalname,
          fileSize: file.size,
          status: 'FAILED',
          errorReason: error?.message ?? 'PARSING_ERROR',
          durationMs: Date.now() - startTime,
        }).catch(() => {});
      }
      logger.error('Resume parse failed:', error);
      next(error);
    }
  },
};
