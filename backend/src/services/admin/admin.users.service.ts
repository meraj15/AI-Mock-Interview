import { prisma } from '../../config/database';
import { NotFoundError, ValidationError } from '../../errors/AppError';
import { telemetryService } from '../telemetry.service';
import { convertToCsv } from './admin.helper';

export interface UserListParams {
  page?: number;
  limit?: number;
  search?: string;
  tier?: 'ALL' | 'FREE' | 'PRO';
  status?: 'ALL' | 'ACTIVE' | 'INACTIVE';
  highUsage?: boolean;
  paymentFailed?: boolean;
  sort?: 'newest' | 'oldest' | 'highest_usage' | 'highest_spend' | 'latest_active';
}

export class AdminUsersService {
  async listUsers(params: UserListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    // Search query on email, id, or profile fullName
    if (params.search && params.search.trim().length > 0) {
      const q = params.search.trim();
      where.OR = [
        { email: { contains: q, mode: 'insensitive' } },
        { id: { equals: q } },
        { profile: { fullName: { contains: q, mode: 'insensitive' } } },
      ];
    }

    // Status filter
    if (params.status === 'ACTIVE') {
      where.isActive = true;
    } else if (params.status === 'INACTIVE') {
      where.isActive = false;
    }

    // Tier filter
    if (params.tier === 'PRO') {
      where.entitlements = { some: { feature: 'PREMIUM', status: 'ACTIVE' } };
    } else if (params.tier === 'FREE') {
      where.NOT = {
        entitlements: { some: { feature: 'PREMIUM', status: 'ACTIVE' } },
      };
    }

    // Payment failed filter
    if (params.paymentFailed) {
      where.paymentTransactions = { some: { status: 'FAILED' } };
    }

    // Sort order
    let orderBy: any = { createdAt: 'desc' };
    if (params.sort === 'oldest') {
      orderBy = { createdAt: 'asc' };
    } else if (params.sort === 'latest_active') {
      orderBy = { lastLoginAt: 'desc' };
    }

    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          profile: {
            select: { fullName: true, targetRole: true, experienceYears: true },
          },
          subscriptions: {
            take: 1,
            orderBy: { createdAt: 'desc' },
            include: { plan: { select: { name: true, tier: true, billingInterval: true } } },
          },
          entitlements: {
            where: { feature: 'PREMIUM' },
            take: 1,
          },
          usageQuotas: {
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
          _count: {
            select: { interviewSessions: true, paymentTransactions: true },
          },
          paymentTransactions: {
            where: { status: 'CAPTURED' },
            select: { amount: true },
          },
        },
      }),
    ]);

    const formattedUsers = users.map((u: any) => {
      const activeEntitlement = u.entitlements.find((e: any) => e.status === 'ACTIVE');
      const isPro = Boolean(activeEntitlement);
      const sub = u.subscriptions[0];
      const quota = u.usageQuotas[0];
      const maxInterviews = isPro ? 30 : 2;
      const interviewsUsed = quota?.interviewsUsed ?? 0;
      const totalSpendPaise = u.paymentTransactions.reduce((acc: number, t: any) => acc + t.amount, 0);

      return {
        id: u.id,
        name: u.profile?.fullName || 'Anonymous',
        email: u.email,
        targetRole: u.profile?.targetRole || 'Not set',
        role: (u as any).role || 'USER',
        tier: isPro ? 'PRO' : 'FREE',
        subscriptionStatus: sub?.status || 'NONE',
        planName: sub?.plan?.name || (isPro ? 'Pro Entitlement' : 'Free Plan'),
        isActive: u.isActive,
        isVerified: u.isVerified,
        createdAt: u.createdAt.toISOString(),
        lastLoginAt: u.lastLoginAt ? u.lastLoginAt.toISOString() : null,
        interviewsUsed,
        interviewsRemaining: Math.max(0, maxInterviews - interviewsUsed),
        totalInterviews: u._count.interviewSessions,
        totalPayments: u._count.paymentTransactions,
        totalSpendRupees: Math.round(totalSpendPaise / 100),
      };
    });

    return {
      users: formattedUsers,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getUserDetails(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        subscriptions: {
          orderBy: { createdAt: 'desc' },
          include: { plan: true },
        },
        entitlements: true,
        usageQuotas: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
        interviewSessions: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: {
            id: true,
            role: true,
            type: true,
            difficulty: true,
            score: true,
            hiringBand: true,
            durationSecs: true,
            createdAt: true,
          },
        },
        paymentTransactions: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          include: {
            subscription: { include: { plan: { select: { name: true } } } },
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundError(`User with id ${userId} not found`);
    }

    // Aggregate statistics
    const [allInterviewStats, aiUsageAggregate, resumeUploads] = await Promise.all([
      prisma.interviewSession.aggregate({
        where: { userId },
        _count: { id: true },
        _avg: { score: true },
        _max: { score: true },
        _min: { score: true },
      }),
      prisma.aiTelemetryLog.aggregate({
        where: { userId },
        _count: { id: true },
        _sum: { totalTokens: true },
        _avg: { latencyMs: true },
      }),
      prisma.resumeParseLog.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
    ]);

    const activeEntitlement = user.entitlements.find(
      (e: any) => e.feature === 'PREMIUM' && e.status === 'ACTIVE'
    );
    const activeSub = user.subscriptions.find((s: any) => s.status === 'ACTIVE');
    const latestQuota = user.usageQuotas[0];
    const maxInterviews = activeEntitlement ? 30 : 2;

    return {
      user: {
        id: user.id,
        email: user.email,
        isActive: user.isActive,
        isVerified: user.isVerified,
        role: (user as any).role || 'USER',
        createdAt: user.createdAt.toISOString(),
        lastLoginAt: user.lastLoginAt ? user.lastLoginAt.toISOString() : null,
      },
      profile: user.profile
        ? {
            fullName: user.profile.fullName,
            phone: user.profile.phone,
            targetRole: user.profile.targetRole,
            experienceYears: user.profile.experienceYears,
            bio: user.profile.bio,
            skills: user.profile.skills,
            education: user.profile.education,
            projects: user.profile.projects,
            certifications: user.profile.certifications,
          }
        : null,
      subscription: activeSub
        ? {
            id: activeSub.id,
            planName: activeSub.plan.name,
            tier: activeSub.plan.tier,
            billingInterval: activeSub.plan.billingInterval,
            status: activeSub.status,
            currentPeriodStart: activeSub.currentPeriodStart?.toISOString() ?? null,
            currentPeriodEnd: activeSub.currentPeriodEnd?.toISOString() ?? null,
            autoRenew: activeSub.autoRenew,
            providerSubscriptionId: activeSub.providerSubscriptionId,
          }
        : null,
      entitlement: {
        isPro: Boolean(activeEntitlement),
        status: activeEntitlement?.status ?? 'INACTIVE',
        expiresAt: activeEntitlement?.expiresAt?.toISOString() ?? null,
      },
      usage: {
        interviewsUsed: latestQuota?.interviewsUsed ?? 0,
        interviewsRemaining: Math.max(0, maxInterviews - (latestQuota?.interviewsUsed ?? 0)),
        resumeScansUsed: latestQuota?.resumeScansUsed ?? 0,
        voiceSecondsUsed: latestQuota?.voiceSecondsUsed ?? 0,
        periodKey: latestQuota?.periodKey ?? 'default',
      },
      interviewMetrics: {
        totalInterviews: allInterviewStats._count.id,
        averageScore: Math.round(allInterviewStats._avg.score ?? 0),
        highestScore: allInterviewStats._max.score ?? 0,
        lowestScore: allInterviewStats._min.score ?? 0,
        recentSessions: user.interviewSessions.map((s: any) => ({
          id: s.id,
          role: s.role,
          type: s.type,
          difficulty: s.difficulty,
          score: s.score,
          hiringBand: s.hiringBand,
          durationSecs: s.durationSecs,
          createdAt: s.createdAt.toISOString(),
        })),
      },
      payments: user.paymentTransactions.map((tx: any) => ({
        id: tx.id,
        amountRupees: Math.round(tx.amount / 100),
        currency: tx.currency,
        status: tx.status,
        providerPaymentId: tx.providerPaymentId,
        paidAt: tx.paidAt?.toISOString() ?? null,
        planName: tx.subscription?.plan?.name ?? 'Plan',
        createdAt: tx.createdAt.toISOString(),
      })),
      resumes: resumeUploads.map((r: any) => ({
        id: r.id,
        fileName: r.fileName,
        fileSizeKb: Math.round(r.fileSize / 1024),
        status: r.status,
        errorReason: r.errorReason,
        durationMs: r.durationMs,
        createdAt: r.createdAt.toISOString(),
      })),
      aiActivity: {
        totalRequests: aiUsageAggregate._count.id,
        totalTokens: aiUsageAggregate._sum.totalTokens ?? 0,
        avgLatencyMs: Math.round(aiUsageAggregate._avg.latencyMs ?? 0),
      },
    };
  }

  async suspendUser(adminId: string, userId: string, reason: string, ipAddress?: string) {
    if (!reason || reason.trim().length < 3) {
      throw new ValidationError('A reason must be provided when suspending a user account');
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundError(`User ${userId} not found`);
    }

    if (!user.isActive) {
      throw new ValidationError('User is already suspended');
    }

    const previousValue = { isActive: user.isActive };
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { isActive: false },
    });

    // Revoke all active refresh tokens immediately for security
    await prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'USER_SUSPEND',
      targetType: 'USER',
      targetId: userId,
      previousValue,
      newValue: { isActive: false },
      reason,
      ipAddress,
    });

    return { success: true, message: `User ${user.email} has been suspended`, user: updatedUser };
  }

  async restoreUser(adminId: string, userId: string, reason: string, ipAddress?: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundError(`User ${userId} not found`);
    }

    const previousValue = { isActive: user.isActive };
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { isActive: true },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'USER_RESTORE',
      targetType: 'USER',
      targetId: userId,
      previousValue,
      newValue: { isActive: true },
      reason: reason || 'Restored by admin',
      ipAddress,
    });

    return { success: true, message: `User ${user.email} has been restored`, user: updatedUser };
  }

  async updateEntitlement(
    adminId: string,
    userId: string,
    status: 'ACTIVE' | 'INACTIVE',
    expiresAt?: Date | null,
    reason?: string,
    ipAddress?: string
  ) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundError(`User ${userId} not found`);
    }

    const currentEntitlement = await prisma.entitlement.findUnique({
      where: { userId_feature: { userId, feature: 'PREMIUM' } },
    });

    const previousValue = currentEntitlement
      ? { status: currentEntitlement.status, expiresAt: currentEntitlement.expiresAt }
      : { status: 'INACTIVE', expiresAt: null };

    const updated = await prisma.entitlement.upsert({
      where: { userId_feature: { userId, feature: 'PREMIUM' } },
      create: {
        userId,
        feature: 'PREMIUM',
        status,
        expiresAt: expiresAt ?? null,
      },
      update: {
        status,
        expiresAt: expiresAt ?? null,
      },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: status === 'ACTIVE' ? 'ENTITLEMENT_GRANT' : 'ENTITLEMENT_REVOKE',
      targetType: 'USER',
      targetId: userId,
      previousValue,
      newValue: { status, expiresAt },
      reason: reason || 'Manual entitlement update by admin',
      ipAddress,
    });

    return {
      success: true,
      message: `Entitlement updated to ${status} for ${user.email}`,
      entitlement: updated,
    };
  }

  async exportUsersCsv(params: UserListParams): Promise<string> {
    const result = await this.listUsers({ ...params, limit: 1000 });
    const rows = result.users.map((u: any) => ({
      ID: u.id,
      Name: u.name,
      Email: u.email,
      Role: u.targetRole,
      Tier: u.tier,
      Plan: u.planName,
      Status: u.isActive ? 'Active' : 'Suspended',
      'Interviews Used': u.interviewsUsed,
      'Interviews Remaining': u.interviewsRemaining,
      'Total Interviews': u.totalInterviews,
      'Total Spend INR': u.totalSpendRupees,
      'Created At': u.createdAt,
      'Last Login': u.lastLoginAt ?? 'Never',
    }));

    return convertToCsv(rows);
  }
}

export const adminUsersService = new AdminUsersService();
