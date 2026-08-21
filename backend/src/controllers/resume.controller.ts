import { Request, Response, NextFunction } from 'express';
import { resumeService } from '../services/resume.service';
import { logger } from '../utils/logger';

export const resumeController = {
  /**
   * POST /api/resume/parse
   * Expects: multipart/form-data with field "file" (PDF / DOC / TXT)
   * Returns: { success: true, profile: ResumeProfile }
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
