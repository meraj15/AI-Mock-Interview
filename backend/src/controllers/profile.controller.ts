import { Response, NextFunction } from 'express';
import { profileService, ProfileService } from '../services/profile.service';
import { updateProfileSchema } from '../validators/profile.validator';
import { AuthenticatedRequest } from '../types/auth.types';
import { UnauthorizedError } from '../errors/AppError';

export class ProfileController {
  constructor(private readonly service: ProfileService = profileService) {}

  getProfile = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
      }

      const profile = await this.service.getProfile(req.user.id);

      res.status(200).json({
        success: true,
        data: { profile },
      });
    } catch (err) {
      next(err);
    }
  };

  updateProfile = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
      }

      const validated = updateProfileSchema.parse(req.body);
      const profile = await this.service.updateProfile(req.user.id, validated);

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: { profile },
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /api/profile/merge-resume
   * Merges resume-extracted data into the authenticated user's existing profile.
   * Existing user-provided values are NEVER overwritten; only empty fields are filled.
   */
  mergeResumeProfile = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
      }

      // Reuse update schema for validation — all fields optional
      const validated = updateProfileSchema.parse(req.body);
      const profile = await this.service.mergeResumeProfile(req.user.id, validated);

      res.status(200).json({
        success: true,
        message: 'Profile merged successfully',
        data: { profile },
      });
    } catch (err) {
      next(err);
    }
  };
}

export const profileController = new ProfileController();
