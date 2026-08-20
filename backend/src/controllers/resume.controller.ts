import { Request, Response, NextFunction } from 'express';
import { resumeService } from '../services/resume.service';

export class ResumeController {
  /**
   * POST /api/v1/resume/parse
   * Handles PDF/DOC file parsing and returns structured candidate profile JSON
   */
  async parseFile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const fileName = (req.body?.fileName as string) || 'Uploaded_Resume.pdf';
      const profile = await resumeService.parseResume(fileName);

      res.status(200).json({
        success: true,
        message: 'Resume parsed successfully',
        profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/resume/parse-text
   * Handles pasted raw text and returns structured candidate profile JSON
   */
  async parseText(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const text = (req.body?.text as string) || '';
      const profile = await resumeService.parseRawText(text);

      res.status(200).json({
        success: true,
        message: 'Resume text structured successfully',
        profile,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const resumeController = new ResumeController();
