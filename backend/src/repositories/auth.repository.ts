import { prisma } from '../config/database';
import {
  User,
  RefreshToken,
  PasswordResetToken,
  PasswordResetOtp,
  EmailVerificationOtp,
  UserProfile,
} from '@prisma/client';

export class AuthRepository {
  async findUserByEmail(email: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { email: email.toLowerCase().trim() },
    });
  }

  async findUserById(id: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { id },
    });
  }

  async createUser(email: string, passwordHash: string): Promise<User> {
    return prisma.user.create({
      data: {
        email: email.toLowerCase().trim(),
        passwordHash,
      },
    });
  }

  /**
   * Creates both the User and UserProfile records in a single atomic transaction.
   */
  async createUserWithProfile(params: {
    email: string;
    passwordHash: string;
    fullName?: string | null;
  }): Promise<{ user: User; profile: UserProfile }> {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: params.email.toLowerCase().trim(),
          passwordHash: params.passwordHash,
          isVerified: true,
          isActive: true,
        },
      });

      const profile = await tx.userProfile.create({
        data: {
          userId: user.id,
          fullName: params.fullName?.trim() || null,
          skills: [],
          education: [],
          projects: [],
          certifications: [],
        },
      });

      return { user, profile };
    });
  }

  async updateLastLogin(userId: string): Promise<User> {
    return prisma.user.update({
      where: { id: userId },
      data: { lastLoginAt: new Date() },
    });
  }

  async updateUserPassword(userId: string, passwordHash: string): Promise<User> {
    return prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
  }

  // ── Refresh Token ───────────────────────────────────────────────────────────

  async saveRefreshToken(userId: string, tokenHash: string, expiresAt: Date): Promise<RefreshToken> {
    return prisma.refreshToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  async findRefreshToken(tokenHash: string): Promise<(RefreshToken & { user: User }) | null> {
    return prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });
  }

  async revokeRefreshToken(id: string): Promise<RefreshToken> {
    return prisma.refreshToken.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
  }

  async revokeAllUserRefreshTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async deleteExpiredRefreshTokens(): Promise<number> {
    const result = await prisma.refreshToken.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });
    return result.count;
  }

  // ── Dedicated Password Reset OTP ───────────────────────────────────────────

  /**
   * Delete existing unused password reset OTPs for this user, then create a new one.
   */
  async upsertPasswordResetOtp(params: {
    userId: string;
    email: string;
    otpHash: string;
    expiresAt: Date;
  }): Promise<PasswordResetOtp> {
    await prisma.passwordResetOtp.deleteMany({
      where: { userId: params.userId },
    });

    return prisma.passwordResetOtp.create({
      data: {
        userId: params.userId,
        email: params.email.toLowerCase().trim(),
        otpHash: params.otpHash,
        expiresAt: params.expiresAt,
      },
    });
  }

  async findLatestPasswordResetOtp(email: string): Promise<PasswordResetOtp | null> {
    return prisma.passwordResetOtp.findFirst({
      where: { email: email.toLowerCase().trim() },
      orderBy: { createdAt: 'desc' },
    });
  }

  async incrementPasswordResetOtpAttempts(otpId: string): Promise<void> {
    await prisma.passwordResetOtp.update({
      where: { id: otpId },
      data: { attempts: { increment: 1 } },
    });
  }

  async consumePasswordResetOtp(otpId: string): Promise<void> {
    await prisma.passwordResetOtp.update({
      where: { id: otpId },
      data: { consumedAt: new Date() },
    });
  }

  // ── Password Reset Token ────────────────────────────────────────────────────

  async createPasswordResetToken(
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<PasswordResetToken> {
    await prisma.passwordResetToken.deleteMany({
      where: { userId },
    });

    return prisma.passwordResetToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  async findPasswordResetToken(tokenHash: string): Promise<PasswordResetToken | null> {
    return prisma.passwordResetToken.findUnique({
      where: { tokenHash },
    });
  }

  /**
   * Atomically updates user's password, consumes the resetToken,
   * revokes all active user refresh sessions, and invalidates any pending reset OTPs.
   */
  async completePasswordReset(
    tokenId: string,
    userId: string,
    newPasswordHash: string,
  ): Promise<void> {
    const now = new Date();
    await prisma.$transaction([
      prisma.passwordResetToken.update({
        where: { id: tokenId },
        data: { usedAt: now },
      }),
      prisma.user.update({
        where: { id: userId },
        data: { passwordHash: newPasswordHash },
      }),
      prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: now },
      }),
      prisma.passwordResetOtp.deleteMany({
        where: { userId },
      }),
    ]);
  }

  // ── Backward-Compatible / Legacy Methods ───────────────────────────────────

  async upsertEmailOtp(params: {
    email: string;
    otpHash: string;
    expiresAt: Date;
    userId?: string | null;
    passwordHash?: string | null;
    fullName?: string | null;
  }): Promise<EmailVerificationOtp> {
    const email = params.email.toLowerCase().trim();
    await prisma.emailVerificationOtp.deleteMany({ where: { email } });

    return prisma.emailVerificationOtp.create({
      data: {
        email,
        otpHash: params.otpHash,
        expiresAt: params.expiresAt,
        userId: params.userId ?? null,
        passwordHash: params.passwordHash ?? null,
        fullName: params.fullName ?? null,
      },
    });
  }

  async findLatestEmailOtp(email: string): Promise<EmailVerificationOtp | null> {
    return prisma.emailVerificationOtp.findFirst({
      where: { email: email.toLowerCase().trim() },
      orderBy: { createdAt: 'desc' },
    });
  }

  async incrementOtpAttempts(otpId: string): Promise<void> {
    await prisma.emailVerificationOtp.update({
      where: { id: otpId },
      data: { attempts: { increment: 1 } },
    });
  }

  async consumeEmailOtp(otpId: string, userId: string): Promise<void> {
    const now = new Date();
    await prisma.$transaction([
      prisma.emailVerificationOtp.update({
        where: { id: otpId },
        data: { consumedAt: now },
      }),
      prisma.user.update({
        where: { id: userId },
        data: { emailVerifiedAt: now, isVerified: true },
      }),
    ]);
  }
}

export const authRepository = new AuthRepository();
