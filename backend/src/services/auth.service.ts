import { AuthRepository, authRepository } from '../repositories/auth.repository';
import { RegisterInput, LoginInput } from '../validators/auth.validator';
import { hashPassword, verifyPassword, hashToken } from '../utils/password';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from '../utils/token';
import {
  UnauthorizedError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../errors/AppError';
import { AuthResult, AuthTokens, UserResponse } from '../types/auth.types';
import { User } from '@prisma/client';

export class AuthService {
  constructor(private readonly repo: AuthRepository = authRepository) {}

  private sanitizeUser(user: User): UserResponse {
    return {
      id: user.id,
      email: user.email,
      isVerified: user.isVerified,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
    };
  }

  async register(input: RegisterInput): Promise<AuthResult> {
    const email = input.email.toLowerCase().trim();

    // Check existing user
    const existing = await this.repo.findUserByEmail(email);
    if (existing) {
      throw new ConflictError('Email already registered', 'EMAIL_ALREADY_EXISTS');
    }

    // Hash password with Argon2
    const passwordHash = await hashPassword(input.password);

    // Create user
    const user = await this.repo.createUser(email, passwordHash);

    // Generate tokens
    const accessToken = generateAccessToken(user.id);
    const { token: refreshToken, expiresAt } = generateRefreshToken(user.id);

    // Hash & store refresh token
    const tokenHash = hashToken(refreshToken);
    await this.repo.saveRefreshToken(user.id, tokenHash, expiresAt);

    return {
      user: this.sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  async login(input: LoginInput): Promise<AuthResult> {
    const email = input.email.toLowerCase().trim();

    // Find user
    const user = await this.repo.findUserByEmail(email);
    if (!user) {
      throw new UnauthorizedError('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    // Check if account is active
    if (!user.isActive) {
      throw new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED');
    }

    // Verify password
    const isValid = await verifyPassword(input.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedError('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    // Update lastLoginAt
    await this.repo.updateLastLogin(user.id);

    // Generate tokens
    const accessToken = generateAccessToken(user.id);
    const { token: refreshToken, expiresAt } = generateRefreshToken(user.id);

    // Hash & store refresh token
    const tokenHash = hashToken(refreshToken);
    await this.repo.saveRefreshToken(user.id, tokenHash, expiresAt);

    return {
      user: this.sanitizeUser(user),
      accessToken,
      refreshToken,
    };
  }

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    // 1. Verify JWT signature & structure
    let decoded;
    try {
      decoded = verifyRefreshToken(rawRefreshToken);
    } catch {
      throw new UnauthorizedError('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    // 2. Hash raw token and lookup in database
    const tokenHash = hashToken(rawRefreshToken);
    const record = await this.repo.findRefreshToken(tokenHash);

    if (!record) {
      throw new UnauthorizedError('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    // 3. Check revocation
    if (record.revokedAt) {
      throw new UnauthorizedError('Refresh token has been revoked', 'REFRESH_TOKEN_REVOKED');
    }

    // 4. Check expiration
    if (record.expiresAt < new Date()) {
      throw new UnauthorizedError('Refresh token has expired', 'REFRESH_TOKEN_EXPIRED');
    }

    // 5. Check user status
    if (!record.user.isActive) {
      throw new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED');
    }

    // 6. Token rotation: revoke old token
    await this.repo.revokeRefreshToken(record.id);

    // 7. Generate new token pair
    const accessToken = generateAccessToken(record.userId);
    const { token: newRefreshToken, expiresAt } = generateRefreshToken(record.userId);

    // 8. Save new token hash
    const newTokenHash = hashToken(newRefreshToken);
    await this.repo.saveRefreshToken(record.userId, newTokenHash, expiresAt);

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  async logout(rawRefreshToken: string): Promise<void> {
    try {
      const tokenHash = hashToken(rawRefreshToken);
      const record = await this.repo.findRefreshToken(tokenHash);
      if (record && !record.revokedAt) {
        await this.repo.revokeRefreshToken(record.id);
      }
    } catch {
      // Graceful no-op on malformed tokens
    }
  }

  async logoutAll(userId: string): Promise<void> {
    await this.repo.revokeAllUserRefreshTokens(userId);
  }

  async getCurrentUser(userId: string): Promise<UserResponse> {
    const user = await this.repo.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }
    if (!user.isActive) {
      throw new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED');
    }
    return this.sanitizeUser(user);
  }
}

export const authService = new AuthService();
