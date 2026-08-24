import { prisma } from '../config/database';
import { User, RefreshToken, PasswordResetToken } from '@prisma/client';

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

  async updateLastLogin(userId: string): Promise<User> {
    return prisma.user.update({
      where: { id: userId },
      data: { lastLoginAt: new Date() },
    });
  }

  async saveRefreshToken(userId: string, tokenHash: string, expiresAt: Date): Promise<RefreshToken> {
    return prisma.refreshToken.create({
      data: {
        userId,
        tokenHash,
        expiresAt,
      },
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

  async revokeAllUserRefreshTokens(userId: string): Promise<{ count: number }> {
    return prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /** Delete any existing unused reset tokens for the user, then create a new one. */
  async upsertPasswordResetToken(
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<PasswordResetToken> {
    // Clean up old tokens for this user first
    await prisma.passwordResetToken.deleteMany({ where: { userId } });

    return prisma.passwordResetToken.create({
      data: { userId, tokenHash, expiresAt },
    });
  }

  /** Find a reset token by its hash, including the related user. */
  async findPasswordResetToken(
    tokenHash: string,
  ): Promise<(PasswordResetToken & { user: User }) | null> {
    return prisma.passwordResetToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });
  }

  /** Mark the token as used and update the user's password in one transaction. */
  async consumePasswordResetToken(tokenId: string, userId: string, newPasswordHash: string): Promise<void> {
    await prisma.$transaction([
      prisma.passwordResetToken.update({
        where: { id: tokenId },
        data: { usedAt: new Date() },
      }),
      prisma.user.update({
        where: { id: userId },
        data: { passwordHash: newPasswordHash, updatedAt: new Date() },
      }),
      // Revoke all existing refresh tokens for security
      prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);
  }
}

export const authRepository = new AuthRepository();
