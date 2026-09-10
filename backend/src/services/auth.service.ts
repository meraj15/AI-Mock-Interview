import crypto from 'crypto';
import { AuthRepository, authRepository } from '../repositories/auth.repository';
import { profileRepository } from '../repositories/profile.repository';
import {
  RegisterInput,
  LoginInput,
  ForgotPasswordInput,
  VerifyResetOtpInput,
  ResetPasswordInput,
} from '../validators/auth.validator';
import { hashPassword, verifyPassword, hashToken } from '../utils/password';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from '../utils/token';
import { generateOtp, hashOtp, otpExpiresAt, OTP_MAX_ATTEMPTS, OTP_RESEND_COOLDOWN_MS } from '../utils/otp';
import { sendPasswordResetOtpEmail } from './email.service';
import {
  UnauthorizedError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
  AppError,
} from '../errors/AppError';
import { AuthResult, AuthTokens, UserResponse } from '../types/auth.types';
import { User, UserProfile } from '@prisma/client';
import { prisma } from '../config/database';
import { logger } from '../utils/logger';

export class AuthService {
  constructor(private readonly repo: AuthRepository = authRepository) {}

  private sanitizeUser(user: User, profile?: UserProfile | null): UserResponse {
    const hasRole = Boolean(profile?.targetRole && profile.targetRole.trim().length > 0);
    const hasSkills = Boolean(profile?.skills && Array.isArray(profile.skills) && profile.skills.length > 0);
    const isProfileComplete = hasRole && hasSkills;

    return {
      id: user.id,
      email: user.email,
      fullName: profile?.fullName ?? null,
      name: profile?.fullName ?? null,
      targetRole: profile?.targetRole ?? null,
      skills: profile?.skills ?? [],
      isProfileComplete,
      isVerified: user.isVerified,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
    };
  }

  // ── Registration (Immediate Account Creation — No OTP) ──────────────────────

  async register(input: RegisterInput): Promise<AuthResult> {
    const email = input.email.toLowerCase().trim();

    // Check if user already exists
    const existing = await this.repo.findUserByEmail(email);
    if (existing) {
      throw new ConflictError('Email already registered', 'EMAIL_ALREADY_EXISTS');
    }

    // Hash password and create user + profile immediately
    const passwordHash = await hashPassword(input.password);
    const { user, profile } = await this.repo.createUserWithProfile({
      email,
      passwordHash,
      fullName: input.fullName?.trim() || null,
    });

    // Issue authentication tokens
    const accessToken = generateAccessToken(user.id);
    const { token: refreshToken, expiresAt } = generateRefreshToken(user.id);
    const tokenHash = hashToken(refreshToken);
    await this.repo.saveRefreshToken(user.id, tokenHash, expiresAt);

    logger.info('[AuthService] User registered successfully', { userId: user.id });

    return {
      user: this.sanitizeUser(user, profile),
      accessToken,
      refreshToken,
    };
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  async login(input: LoginInput): Promise<AuthResult> {
    const email = input.email.toLowerCase().trim();

    const user = await this.repo.findUserByEmail(email);
    if (!user) {
      throw new UnauthorizedError('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    if (!user.isActive) {
      throw new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED');
    }

    const isValid = await verifyPassword(input.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedError('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    await this.repo.updateLastLogin(user.id);

    const profile = await profileRepository.getProfileByUserId(user.id);

    const accessToken = generateAccessToken(user.id);
    const { token: refreshToken, expiresAt } = generateRefreshToken(user.id);

    const tokenHash = hashToken(refreshToken);
    await this.repo.saveRefreshToken(user.id, tokenHash, expiresAt);

    return {
      user: this.sanitizeUser(user, profile),
      accessToken,
      refreshToken,
    };
  }

  // ── Token Refresh ────────────────────────────────────────────────────────────

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    let decoded;
    try {
      decoded = verifyRefreshToken(rawRefreshToken);
    } catch {
      throw new UnauthorizedError('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    const tokenHash = hashToken(rawRefreshToken);
    const record = await this.repo.findRefreshToken(tokenHash);

    if (!record) {
      throw new UnauthorizedError('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    if (record.revokedAt) {
      throw new UnauthorizedError('Refresh token has been revoked', 'REFRESH_TOKEN_REVOKED');
    }

    if (record.expiresAt < new Date()) {
      throw new UnauthorizedError('Refresh token has expired', 'REFRESH_TOKEN_EXPIRED');
    }

    if (!record.user.isActive) {
      throw new ForbiddenError('Account is disabled', 'ACCOUNT_DISABLED');
    }

    await this.repo.revokeRefreshToken(record.id);

    const accessToken = generateAccessToken(record.userId);
    const { token: newRefreshToken, expiresAt } = generateRefreshToken(record.userId);

    const newTokenHash = hashToken(newRefreshToken);
    await this.repo.saveRefreshToken(record.userId, newTokenHash, expiresAt);

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

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
    const profile = await profileRepository.getProfileByUserId(user.id);
    return this.sanitizeUser(user, profile);
  }

  // ── Password Reset Flow (OTP Exclusively for Forgot Password) ───────────────

  /**
   * Step 1: User enters email.
   * Generates a 6-digit OTP, hashes it, stores in PasswordResetOtp, and emails user.
   * Generic response to prevent email enumeration.
   */
  async forgotPassword(input: ForgotPasswordInput): Promise<void> {
    const email = input.email.toLowerCase().trim();

    const user = await this.repo.findUserByEmail(email);
    if (!user || !user.isActive) {
      logger.info('[AuthService] forgotPassword: user not found or inactive — generic response', { email });
      return;
    }

    // Check resend cooldown
    const latestOtp = await this.repo.findLatestPasswordResetOtp(email);
    if (latestOtp && !latestOtp.consumedAt) {
      const cooldownExpires = latestOtp.createdAt.getTime() + OTP_RESEND_COOLDOWN_MS;
      if (Date.now() < cooldownExpires) {
        const waitSecs = Math.ceil((cooldownExpires - Date.now()) / 1000);
        throw new AppError(
          `Please wait ${waitSecs} seconds before requesting a new code.`,
          429,
          'RESEND_COOLDOWN',
        );
      }
    }

    const otp = generateOtp();
    const otpHash = hashOtp(otp);

    await this.repo.upsertPasswordResetOtp({
      userId: user.id,
      email,
      otpHash,
      expiresAt: otpExpiresAt(),
    });

    try {
      const profile = await prisma.userProfile.findUnique({ where: { userId: user.id } });
      await sendPasswordResetOtpEmail(email, otp, profile?.fullName);
    } catch (err) {
      logger.error('[AuthService] Failed to send password reset OTP email', { err });
      throw new AppError('Failed to send verification email. Please try again later.', 503, 'EMAIL_SEND_FAILED');
    }
  }

  /**
   * Step 2: User enters 6-digit OTP.
   * Verifies OTP against PasswordResetOtp, marks consumed, issues a short-lived resetToken.
   */
  async verifyResetOtp(input: VerifyResetOtpInput): Promise<{ resetToken: string }> {
    const email = input.email.toLowerCase().trim();

    const user = await this.repo.findUserByEmail(email);
    if (!user) {
      throw new UnauthorizedError('Invalid or expired verification code.', 'INVALID_OTP');
    }

    const otpRecord = await this.repo.findLatestPasswordResetOtp(email);

    if (!otpRecord) {
      throw new UnauthorizedError('No active verification code found. Please request a new code.', 'OTP_NOT_FOUND');
    }

    if (otpRecord.consumedAt !== null) {
      throw new UnauthorizedError('This code has already been used. Please request a new one.', 'OTP_CONSUMED');
    }

    if (otpRecord.expiresAt < new Date()) {
      throw new UnauthorizedError('Verification code has expired. Please request a new one.', 'OTP_EXPIRED');
    }

    if (otpRecord.attempts >= OTP_MAX_ATTEMPTS) {
      throw new UnauthorizedError(
        'Too many failed attempts. Please request a new verification code.',
        'OTP_MAX_ATTEMPTS',
      );
    }

    // Compare SHA-256 hashes
    const submittedHash = hashOtp(input.otp);
    if (submittedHash !== otpRecord.otpHash) {
      await this.repo.incrementPasswordResetOtpAttempts(otpRecord.id);
      const remaining = OTP_MAX_ATTEMPTS - (otpRecord.attempts + 1);
      throw new UnauthorizedError(
        remaining > 0
          ? `Invalid code. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining.`
          : 'Too many failed attempts. Please request a new code.',
        'INVALID_OTP',
      );
    }

    // Consume OTP
    await this.repo.consumePasswordResetOtp(otpRecord.id);

    // Issue short-lived reset token (15 minutes)
    const rawResetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = hashToken(rawResetToken);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.repo.createPasswordResetToken(user.id, resetTokenHash, expiresAt);

    return { resetToken: rawResetToken };
  }

  /**
   * Step 3: User enters new password with resetToken.
   * Updates password, consumes resetToken, and invalidates all active sessions.
   */
  async resetPassword(input: ResetPasswordInput): Promise<void> {
    const tokenHash = hashToken(input.resetToken);
    const record = await this.repo.findPasswordResetToken(tokenHash);

    if (!record) {
      throw new UnauthorizedError('Invalid or expired reset token', 'INVALID_RESET_TOKEN');
    }

    if (record.usedAt) {
      throw new UnauthorizedError('Reset token has already been used', 'RESET_TOKEN_USED');
    }

    if (record.expiresAt < new Date()) {
      throw new UnauthorizedError('Reset token has expired', 'RESET_TOKEN_EXPIRED');
    }

    const newPasswordHash = await hashPassword(input.newPassword);
    await this.repo.completePasswordReset(record.id, record.userId, newPasswordHash);

    logger.info('[AuthService] Password reset completed successfully', { userId: record.userId });
  }
}

export const authService = new AuthService();
