import { Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/token';
import { authRepository } from '../repositories/auth.repository';
import { UnauthorizedError, ForbiddenError } from '../errors/AppError';
import { AuthenticatedRequest } from '../types/auth.types';

/**
 * Middleware to protect routes requiring JWT access token authentication.
 */
export async function authMiddleware(
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    next(new UnauthorizedError('Missing or malformed authorization header', 'UNAUTHORIZED'));
    return;
  }

  const token = authHeader.substring(7).trim();

  try {
    const payload = verifyAccessToken(token);

    // Verify user exists and is active
    const user = await authRepository.findUserById(payload.sub);
    if (!user) {
      next(new UnauthorizedError('User account not found', 'UNAUTHORIZED'));
      return;
    }

    if (!user.isActive) {
      next(new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED'));
      return;
    }

    req.user = {
      id: user.id,
      email: user.email,
      isVerified: user.isVerified,
      isActive: user.isActive,
    };

    next();
  } catch {
    next(new UnauthorizedError('Invalid or expired access token', 'UNAUTHORIZED'));
  }
}
