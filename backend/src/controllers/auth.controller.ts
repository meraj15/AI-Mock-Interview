import { Response, NextFunction } from 'express';
import { authService, AuthService } from '../services/auth.service';
import {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../validators/auth.validator';
import { AuthenticatedRequest } from '../types/auth.types';
import { UnauthorizedError } from '../errors/AppError';

export class AuthController {
  constructor(private readonly service: AuthService = authService) {}

  register = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = registerSchema.parse(req.body);
      const result = await this.service.register(validated);

      res.status(201).json({
        success: true,
        message: 'Registration successful',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  login = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = loginSchema.parse(req.body);
      const result = await this.service.login(validated);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  refresh = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = refreshTokenSchema.parse(req.body);
      const result = await this.service.refresh(validated.refreshToken);

      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  getCurrentUser = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
      }

      const user = await this.service.getCurrentUser(req.user.id);

      res.status(200).json({
        success: true,
        data: { user },
      });
    } catch (err) {
      next(err);
    }
  };

  logout = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { refreshToken } = req.body ?? {};
      if (typeof refreshToken === 'string' && refreshToken.length > 0) {
        await this.service.logout(refreshToken);
      }

      res.status(200).json({
        success: true,
        message: 'Logged out successfully',
      });
    } catch (err) {
      next(err);
    }
  };

  logoutAll = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized', 'UNAUTHORIZED');
      }

      await this.service.logoutAll(req.user.id);

      res.status(200).json({
        success: true,
        message: 'Logged out from all devices',
      });
    } catch (err) {
      next(err);
    }
  };

  forgotPassword = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = forgotPasswordSchema.parse(req.body);
      const result = await this.service.forgotPassword(validated);

      res.status(200).json({
        success: true,
        message: 'If that email exists, a reset code has been sent.',
        // otp is included in dev mode so you can test without an email service.
        // Remove `data` in production and send the OTP via email instead.
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  resetPassword = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = resetPasswordSchema.parse(req.body);
      await this.service.resetPassword(validated);

      res.status(200).json({
        success: true,
        message: 'Password reset successfully. Please sign in with your new password.',
      });
    } catch (err) {
      next(err);
    }
  };
}

export const authController = new AuthController();
