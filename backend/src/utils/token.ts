import jwt, { JwtPayload, SignOptions } from 'jsonwebtoken';
import { config } from '../config';

export interface AccessTokenPayload extends JwtPayload {
  sub: string;
  type: 'access';
}

export interface RefreshTokenPayload extends JwtPayload {
  sub: string;
  type: 'refresh';
}

/**
 * Generate a short-lived access token (JWT).
 */
export function generateAccessToken(userId: string): string {
  const payload: AccessTokenPayload = {
    sub: userId,
    type: 'access',
  };

  const options: SignOptions = {
    expiresIn: config.jwt.accessExpiresIn as SignOptions['expiresIn'],
  };

  return jwt.sign(payload, config.jwt.accessSecret, options);
}

/**
 * Generate a long-lived refresh token (JWT) with calculated expiration Date.
 */
export function generateRefreshToken(userId: string): { token: string; expiresAt: Date } {
  const payload: RefreshTokenPayload = {
    sub: userId,
    type: 'refresh',
  };

  const options: SignOptions = {
    expiresIn: config.jwt.refreshExpiresIn as SignOptions['expiresIn'],
  };

  const token = jwt.sign(payload, config.jwt.refreshSecret, options);

  // Parse expiration (default 7 days if parsing fails)
  const decoded = jwt.decode(token) as JwtPayload | null;
  const expiresAt = decoded?.exp
    ? new Date(decoded.exp * 1000)
    : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  return { token, expiresAt };
}

/**
 * Verify and decode an access token.
 */
export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, config.jwt.accessSecret) as AccessTokenPayload;
  if (decoded.type !== 'access') {
    throw new Error('Invalid token type');
  }
  return decoded;
}

/**
 * Verify and decode a refresh token.
 */
export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const decoded = jwt.verify(token, config.jwt.refreshSecret) as RefreshTokenPayload;
  if (decoded.type !== 'refresh') {
    throw new Error('Invalid token type');
  }
  return decoded;
}
