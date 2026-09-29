import { prisma } from '../../config/database';
import { NotFoundError } from '../../errors/AppError';
import { telemetryService } from '../telemetry.service';

export interface SubscriptionListParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  planCode?: string;
}

export class AdminSubscriptionsService {
  async listSubscriptions(params: SubscriptionListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.search && params.search.trim().length > 0) {
      const q = params.search.trim();
      where.OR = [
        { providerSubscriptionId: { contains: q, mode: 'insensitive' } },
        { user: { email: { contains: q, mode: 'insensitive' } } },
      ];
    }

    if (params.status && params.status !== 'ALL') {
      where.status = params.status;
    }

    if (params.planCode && params.planCode !== 'ALL') {
      where.plan = { code: params.planCode };
    }

    const [total, subscriptions] = await Promise.all([
      prisma.subscription.count({ where }),
      prisma.subscription.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: { id: true, email: true, profile: { select: { fullName: true } } },
          },
          plan: true,
          _count: { select: { paymentTransactions: true } },
        },
      }),
    ]);

    return {
      subscriptions: subscriptions.map((s: any) => ({
        id: s.id,
        userId: s.userId,
        userName: s.user.profile?.fullName || 'Anonymous',
        userEmail: s.user.email,
        planName: s.plan.name,
        planCode: s.plan.code,
        priceRupees: Math.round(s.plan.priceInPaise / 100),
        billingInterval: s.plan.billingInterval,
        status: s.status,
        providerSubscriptionId: s.providerSubscriptionId,
        autoRenew: s.autoRenew,
        startedAt: s.startedAt ? s.startedAt.toISOString() : null,
        currentPeriodStart: s.currentPeriodStart ? s.currentPeriodStart.toISOString() : null,
        currentPeriodEnd: s.currentPeriodEnd ? s.currentPeriodEnd.toISOString() : null,
        cancelledAt: s.cancelledAt ? s.cancelledAt.toISOString() : null,
        totalPayments: s._count.paymentTransactions,
        createdAt: s.createdAt.toISOString(),
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getSubscriptionStats() {
    const [statusCounts, activePlans, totalUsers] = await Promise.all([
      prisma.subscription.groupBy({
        by: ['status'],
        _count: { id: true },
      }),
      prisma.subscription.findMany({
        where: { status: 'ACTIVE' },
        include: { plan: true },
      }),
      prisma.user.count(),
    ]);

    let mrrPaise = 0;
    let monthlyCount = 0;
    let yearlyCount = 0;

    for (const sub of activePlans) {
      if (sub.plan.billingInterval === 'MONTHLY') {
        mrrPaise += sub.plan.priceInPaise;
        monthlyCount++;
      } else if (sub.plan.billingInterval === 'YEARLY') {
        mrrPaise += Math.round(sub.plan.priceInPaise / 12);
        yearlyCount++;
      }
    }

    const countsMap = new Map<string, number>(statusCounts.map((c: any) => [c.status, c._count.id]));
    const activeCount: number = countsMap.get('ACTIVE') ?? 0;
    const cancelledCount: number = countsMap.get('CANCELLED') ?? 0;
    const haltedCount: number = countsMap.get('HALTED') ?? 0;

    return {
      mrrRupees: Math.round(mrrPaise / 100),
      arrRupees: Math.round((mrrPaise * 12) / 100),
      activeSubscriptions: activeCount,
      cancelledSubscriptions: cancelledCount,
      haltedSubscriptions: haltedCount,
      monthlySubscriptions: monthlyCount,
      yearlySubscriptions: yearlyCount,
      churnRatePercent:
        activeCount + cancelledCount > 0
          ? Math.round((cancelledCount / (activeCount + cancelledCount)) * 1000) / 10
          : 0,
      proPenetrationPercent:
        totalUsers > 0 ? Math.round((activeCount / totalUsers) * 1000) / 10 : 0,
    };
  }

  async cancelSubscription(
    adminId: string,
    subscriptionId: string,
    reason: string,
    ipAddress?: string
  ) {
    const sub = await prisma.subscription.findUnique({
      where: { id: subscriptionId },
      include: { user: true },
    });

    if (!sub) {
      throw new NotFoundError(`Subscription ${subscriptionId} not found`);
    }

    const previousValue = { status: sub.status, autoRenew: sub.autoRenew };
    const updated = await prisma.subscription.update({
      where: { id: subscriptionId },
      data: {
        status: 'CANCELLED',
        autoRenew: false,
        cancelledAt: new Date(),
      },
    });

    // Revoke entitlement feature
    await prisma.entitlement.updateMany({
      where: { userId: sub.userId, feature: 'PREMIUM' },
      data: { status: 'INACTIVE' },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'SUBSCRIPTION_CANCEL',
      targetType: 'SUBSCRIPTION',
      targetId: subscriptionId,
      previousValue,
      newValue: { status: 'CANCELLED', autoRenew: false },
      reason: reason || 'Cancelled by admin',
      ipAddress,
    });

    return {
      success: true,
      message: `Subscription for ${sub.user.email} cancelled successfully`,
      subscription: updated,
    };
  }
}

export const adminSubscriptionsService = new AdminSubscriptionsService();
