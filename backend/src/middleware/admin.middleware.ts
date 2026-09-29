import { Response, NextFunction } from 'express';
import { ForbiddenError, UnauthorizedError } from '../errors/AppError';
import { AuthenticatedRequest } from '../types/auth.types';

/**
 * Middleware ensuring the authenticated user has ADMIN privileges.
 * Must be mounted AFTER authMiddleware.
 * Returns 403 Forbidden for normal users.
 */
export function requireAdmin(
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): void {
  if (!req.user) {
    next(new UnauthorizedError('Authentication required', 'UNAUTHORIZED'));
    return;
  }

  const isAdmin = req.user.role === 'ADMIN' || req.user.isAdmin === true;

  if (!isAdmin) {
    next(
      new ForbiddenError(
        'Access denied. Admin privileges required to access this resource.',
        'ADMIN_REQUIRED'
      )
    );
    return;
  }

  next();
}
