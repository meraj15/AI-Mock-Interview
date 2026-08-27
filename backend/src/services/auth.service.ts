import { AuthRepository, authRepository } from '../repositories/auth.repository';
import { profileRepository } from '../repositories/profile.repository';
import { RegisterInput, LoginInput, ForgotPasswordInput, ResetPasswordInput } from '../validators/auth.validator';
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
import crypto from 'crypto';

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

    // Seed a UserProfile immediately so profile data exists from day one.
    // firstName / lastName come from the registration form (optional fields).
    await profileRepository.seedProfileAtRegistration(
      user.id,
      input.firstName ?? null,
      input.lastName ?? null,
    );

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

  // ── Password Reset ──────────────────────────────────────────────────────────

  /**
   * Generate a 6-digit OTP, persist it hashed, and return it.
   * In production you would email this OTP instead of returning it.
   * OTP expires in 15 minutes.
   */
  async forgotPassword(input: ForgotPasswordInput): Promise<{ otp: string }> {
    const email = input.email.toLowerCase().trim();

    // Always respond with success to prevent user enumeration attacks,
    // but only generate a token if the user actually exists.
    const user = await this.repo.findUserByEmail(email);
    if (!user || !user.isActive) {
      // Return a fake success — client has no way to distinguish real vs fake
      return { otp: '' };
    }

    // Generate a cryptographically secure 6-digit OTP
    const otp = String(crypto.randomInt(100000, 999999));
    const tokenHash = hashToken(otp);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    await this.repo.upsertPasswordResetToken(user.id, tokenHash, expiresAt);

    // TODO: In production — send otp via email and return { otp: '' }
    return { otp };
  }

  /**
   * Verify the OTP and update the user's password.
   */
  async resetPassword(input: ResetPasswordInput): Promise<void> {
    const email = input.email.toLowerCase().trim();

    const user = await this.repo.findUserByEmail(email);
    if (!user) {
      throw new UnauthorizedError('Invalid or expired reset code', 'INVALID_RESET_TOKEN');
    }

    const tokenHash = hashToken(input.otp);
    const record = await this.repo.findPasswordResetToken(tokenHash);

    if (!record || record.userId !== user.id) {
      throw new UnauthorizedError('Invalid or expired reset code', 'INVALID_RESET_TOKEN');
    }

    if (record.usedAt) {
      throw new UnauthorizedError('Reset code has already been used', 'RESET_TOKEN_USED');
    }

    if (record.expiresAt < new Date()) {
      throw new UnauthorizedError('Reset code has expired', 'RESET_TOKEN_EXPIRED');
    }

    const newPasswordHash = await hashPassword(input.newPassword);
    await this.repo.consumePasswordResetToken(record.id, user.id, newPasswordHash);
  }
}

export const authService = new AuthService();
