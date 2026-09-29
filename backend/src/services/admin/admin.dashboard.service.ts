import { prisma } from '../../config/database';
import {
  parseDateRange,
  calculatePercentageChange,
  estimateAiCostInPaise,
} from './admin.helper';

export interface DashboardOverview {
  dateRange: {
    startDate: string;
    endDate: string;
    label: string;
  };
  kpis: {
    totalUsers: { value: number; changePercent: number | null };
    activeUsers: { value: number; changePercent: number | null };
    proUsers: { value: number; changePercent: number | null };
    freeUsers: { value: number; changePercent: number | null };
    activeSubscriptions: { value: number; changePercent: number | null };
    revenueRupees: { value: number; changePercent: number | null };
    interviewsCompleted: { value: number; changePercent: number | null };
    aiCostRupees: { value: number; changePercent: number | null };
  };
  charts: {
    revenueOverTime: Array<{ date: string; revenue: number }>;
    userGrowthOverTime: Array<{ date: string; users: number }>;
    interviewActivityOverTime: Array<{ date: string; total: number; avgScore: number }>;
  };
  subscriptionDistribution: {
    freeUsers: number;
    proMonthly: number;
    proYearly: number;
    halted: number;
    cancelled: number;
    expired: number;
  };
  aiUsageSummary: {
    totalRequests: number;
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
    estimatedCostRupees: number;
    averageLatencyMs: number;
    errorRatePercent: number;
  };
  recentPayments: Array<{
    id: string;
    userId: string;
    userEmail: string;
    planName: string;
    amountRupees: number;
    status: string;
    paidAt: string | null;
    providerPaymentId: string | null;
  }>;
  recentErrors: Array<{
    id: string;
    service: string;
    operation: string;
    error: string;
    status: number;
    timestamp: string;
  }>;
}

export class AdminDashboardService {
  async getOverview(range?: string, customStart?: string, customEnd?: string): Promise<DashboardOverview> {
    const dates = parseDateRange(range, customStart, customEnd);
    const { startDate, endDate, previousStartDate, previousEndDate } = dates;

    // Parallel aggregate queries for high performance without N+1 loops
    const [
      totalUsersCount,
      prevTotalUsersCount,
      activeUsersCount,
      prevActiveUsersCount,
      proUsersCount,
      prevProUsersCount,
      activeSubscriptionsCount,
      prevActiveSubscriptionsCount,
      revenueCurrentAggregate,
      revenuePrevAggregate,
      interviewsCurrentCount,
      interviewsPrevCount,
      aiLogsCurrentAggregate,
      aiLogsPrevAggregate,
      capturedPayments,
      userRegistrations,
      interviewSessions,
      subscriptionTiers,
      recentPaymentRecords,
      recentErrorRecords,
    ] = await Promise.all([
      // 1. Total users
      prisma.user.count(),
      prisma.user.count({ where: { createdAt: { lte: previousEndDate } } }),

      // 2. Active users (logged in or interviewed in range)
      prisma.user.count({
        where: {
          OR: [
            { lastLoginAt: { gte: startDate, lte: endDate } },
            { interviewSessions: { some: { createdAt: { gte: startDate, lte: endDate } } } },
          ],
        },
      }),
      prisma.user.count({
        where: {
          OR: [
            { lastLoginAt: { gte: previousStartDate, lte: previousEndDate } },
            { interviewSessions: { some: { createdAt: { gte: previousStartDate, lte: previousEndDate } } } },
          ],
        },
      }),

      // 3. Pro users count
      prisma.entitlement.count({
        where: { feature: 'PREMIUM', status: 'ACTIVE' },
      }),
      prisma.entitlement.count({
        where: { feature: 'PREMIUM', status: 'ACTIVE', createdAt: { lte: previousEndDate } },
      }),

      // 4. Active subscriptions
      prisma.subscription.count({ where: { status: 'ACTIVE' } }),
      prisma.subscription.count({ where: { status: 'ACTIVE', createdAt: { lte: previousEndDate } } }),

      // 5. Revenue (only CAPTURED / successful payments)
      prisma.paymentTransaction.aggregate({
        where: { status: 'CAPTURED', createdAt: { gte: startDate, lte: endDate } },
        _sum: { amount: true },
      }),
      prisma.paymentTransaction.aggregate({
        where: { status: 'CAPTURED', createdAt: { gte: previousStartDate, lte: previousEndDate } },
        _sum: { amount: true },
      }),

      // 6. Interviews completed
      prisma.interviewSession.count({
        where: { createdAt: { gte: startDate, lte: endDate } },
      }),
      prisma.interviewSession.count({
        where: { createdAt: { gte: previousStartDate, lte: previousEndDate } },
      }),

      // 7. AI telemetry aggregates for current and previous period
      prisma.aiTelemetryLog.aggregate({
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
        _sum: { inputTokens: true, outputTokens: true },
        _avg: { latencyMs: true },
      }),
      prisma.aiTelemetryLog.aggregate({
        where: { createdAt: { gte: previousStartDate, lte: previousEndDate } },
        _sum: { inputTokens: true, outputTokens: true },
      }),

      // 8. Payment transactions for revenue chart
      prisma.paymentTransaction.findMany({
        where: { status: 'CAPTURED', createdAt: { gte: startDate, lte: endDate } },
        select: { amount: true, createdAt: true },
        orderBy: { createdAt: 'asc' },
      }),

      // 9. Users for user growth chart
      prisma.user.findMany({
        where: { createdAt: { gte: startDate, lte: endDate } },
        select: { createdAt: true },
        orderBy: { createdAt: 'asc' },
      }),

      // 10. Interview sessions for activity chart
      prisma.interviewSession.findMany({
        where: { createdAt: { gte: startDate, lte: endDate } },
        select: { score: true, createdAt: true },
        orderBy: { createdAt: 'asc' },
      }),

      // 11. Subscriptions distribution
      prisma.subscription.groupBy({
        by: ['status'],
        _count: { id: true },
      }),

      // 12. Recent payments (top 10)
      prisma.paymentTransaction.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { email: true } },
          subscription: { include: { plan: { select: { name: true } } } },
        },
      }),

      // 13. Recent errors (top 10)
      prisma.aiTelemetryLog.findMany({
        where: { status: { gte: 400 } },
        take: 10,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    // Subscriptions detailed plan split
    const [proMonthlySubs, proYearlySubs] = await Promise.all([
      prisma.subscription.count({
        where: {
          status: 'ACTIVE',
          plan: { billingInterval: 'MONTHLY' },
        },
      }),
      prisma.subscription.count({
        where: {
          status: 'ACTIVE',
          plan: { billingInterval: 'YEARLY' },
        },
      }),
    ]);

    const freeUsersCount = Math.max(0, totalUsersCount - proUsersCount);
    const prevFreeUsersCount = Math.max(0, prevTotalUsersCount - prevProUsersCount);

    const revenueCurrentPaise = revenueCurrentAggregate._sum.amount ?? 0;
    const revenuePrevPaise = revenuePrevAggregate._sum.amount ?? 0;

    const currentAiCost = estimateAiCostInPaise(
      aiLogsCurrentAggregate._sum.inputTokens ?? 0,
      aiLogsCurrentAggregate._sum.outputTokens ?? 0
    );
    const prevAiCost = estimateAiCostInPaise(
      aiLogsPrevAggregate._sum.inputTokens ?? 0,
      aiLogsPrevAggregate._sum.outputTokens ?? 0
    );

    // Group revenue by date (YYYY-MM-DD)
    const revenueByDayMap = new Map<string, number>();
    for (const tx of capturedPayments) {
      const day = tx.createdAt.toISOString().slice(0, 10);
      revenueByDayMap.set(day, (revenueByDayMap.get(day) ?? 0) + tx.amount / 100);
    }
    const revenueOverTime = Array.from(revenueByDayMap.entries()).map(([date, revenue]) => ({
      date,
      revenue: Math.round(revenue),
    }));

    // Group user signups by date
    const usersByDayMap = new Map<string, number>();
    for (const u of userRegistrations) {
      const day = u.createdAt.toISOString().slice(0, 10);
      usersByDayMap.set(day, (usersByDayMap.get(day) ?? 0) + 1);
    }
    const userGrowthOverTime = Array.from(usersByDayMap.entries()).map(([date, users]) => ({
      date,
      users,
    }));

    // Group interview activity by date
    const interviewsByDayMap = new Map<string, { total: number; sumScore: number }>();
    for (const s of interviewSessions) {
      const day = s.createdAt.toISOString().slice(0, 10);
      const curr = interviewsByDayMap.get(day) ?? { total: 0, sumScore: 0 };
      curr.total += 1;
      curr.sumScore += s.score;
      interviewsByDayMap.set(day, curr);
    }
    const interviewActivityOverTime = Array.from(interviewsByDayMap.entries()).map(
      ([date, item]) => ({
        date,
        total: item.total,
        avgScore: Math.round(item.sumScore / item.total),
      })
    );

    // Subscription status breakdown
    const statusMap = new Map<string, number>();
    for (const s of subscriptionTiers) {
      statusMap.set(s.status, s._count.id);
    }

    // AI Error Rate
    const aiErrorsCount = await prisma.aiTelemetryLog.count({
      where: {
        createdAt: { gte: startDate, lte: endDate },
        status: { gte: 400 },
      },
    });
    const totalAiRequests = aiLogsCurrentAggregate._count.id;
    const errorRatePercent =
      totalAiRequests > 0 ? Math.round((aiErrorsCount / totalAiRequests) * 1000) / 10 : 0;

    return {
      dateRange: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        label: dates.label,
      },
      kpis: {
        totalUsers: {
          value: totalUsersCount,
          changePercent: calculatePercentageChange(totalUsersCount, prevTotalUsersCount),
        },
        activeUsers: {
          value: activeUsersCount,
          changePercent: calculatePercentageChange(activeUsersCount, prevActiveUsersCount),
        },
        proUsers: {
          value: proUsersCount,
          changePercent: calculatePercentageChange(proUsersCount, prevProUsersCount),
        },
        freeUsers: {
          value: freeUsersCount,
          changePercent: calculatePercentageChange(freeUsersCount, prevFreeUsersCount),
        },
        activeSubscriptions: {
          value: activeSubscriptionsCount,
          changePercent: calculatePercentageChange(
            activeSubscriptionsCount,
            prevActiveSubscriptionsCount
          ),
        },
        revenueRupees: {
          value: Math.round(revenueCurrentPaise / 100),
          changePercent: calculatePercentageChange(revenueCurrentPaise, revenuePrevPaise),
        },
        interviewsCompleted: {
          value: interviewsCurrentCount,
          changePercent: calculatePercentageChange(interviewsCurrentCount, interviewsPrevCount),
        },
        aiCostRupees: {
          value: Math.round(currentAiCost.totalCostPaise / 100),
          changePercent: calculatePercentageChange(
            currentAiCost.totalCostPaise,
            prevAiCost.totalCostPaise
          ),
        },
      },
      charts: {
        revenueOverTime,
        userGrowthOverTime,
        interviewActivityOverTime,
      },
      subscriptionDistribution: {
        freeUsers: freeUsersCount,
        proMonthly: proMonthlySubs,
        proYearly: proYearlySubs,
        halted: statusMap.get('HALTED') ?? 0,
        cancelled: statusMap.get('CANCELLED') ?? 0,
        expired: statusMap.get('EXPIRED') ?? 0,
      },
      aiUsageSummary: {
        totalRequests: totalAiRequests,
        inputTokens: aiLogsCurrentAggregate._sum.inputTokens ?? 0,
        outputTokens: aiLogsCurrentAggregate._sum.outputTokens ?? 0,
        totalTokens:
          (aiLogsCurrentAggregate._sum.inputTokens ?? 0) +
          (aiLogsCurrentAggregate._sum.outputTokens ?? 0),
        estimatedCostRupees: Math.round(currentAiCost.totalCostPaise / 100),
        averageLatencyMs: Math.round(aiLogsCurrentAggregate._avg.latencyMs ?? 0),
        errorRatePercent,
      },
      recentPayments: recentPaymentRecords.map((tx: any) => ({
        id: tx.id,
        userId: tx.userId,
        userEmail: tx.user.email,
        planName: tx.subscription?.plan?.name ?? 'Subscription',
        amountRupees: Math.round(tx.amount / 100),
        status: tx.status,
        paidAt: tx.paidAt ? tx.paidAt.toISOString() : null,
        providerPaymentId: tx.providerPaymentId,
      })),
      recentErrors: recentErrorRecords.map((err: any) => ({
        id: err.id,
        service: err.provider === 'gemini' ? 'Gemini AI' : err.provider,
        operation: err.operation,
        error: err.errorMessage || `HTTP ${err.status}`,
        status: err.status,
        timestamp: err.createdAt.toISOString(),
      })),
    };
  }
}

export const adminDashboardService = new AdminDashboardService();
