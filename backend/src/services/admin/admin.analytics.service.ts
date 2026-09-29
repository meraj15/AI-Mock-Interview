import { prisma } from '../../config/database';
import { parseDateRange } from './admin.helper';

export class AdminAnalyticsService {
  async getAnalytics(range?: string, customStart?: string, customEnd?: string) {
    const dates = parseDateRange(range, customStart, customEnd);
    const { startDate, endDate } = dates;
    const now = new Date();

    const dauStart = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const wauStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const mauStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      dau,
      wau,
      mau,
      rolesStats,
      difficultyStats,
      typeStats,
      allSessions,
      proUsersCount,
      totalUsersCount,
      freeQuotasAgg,
      proQuotasAgg,
      freeSessionsAgg,
      proSessionsAgg,
      subsCreatedCount,
      paymentsCapturedCount,
      activeSubsCount,
    ] = await Promise.all([
      // DAU
      prisma.user.count({
        where: {
          OR: [
            { lastLoginAt: { gte: dauStart } },
            { interviewSessions: { some: { createdAt: { gte: dauStart } } } },
          ],
        },
      }),
      // WAU
      prisma.user.count({
        where: {
          OR: [
            { lastLoginAt: { gte: wauStart } },
            { interviewSessions: { some: { createdAt: { gte: wauStart } } } },
          ],
        },
      }),
      // MAU
      prisma.user.count({
        where: {
          OR: [
            { lastLoginAt: { gte: mauStart } },
            { interviewSessions: { some: { createdAt: { gte: mauStart } } } },
          ],
        },
      }),

      // Top roles practiced
      prisma.interviewSession.groupBy({
        by: ['role'],
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
        _avg: { score: true },
        orderBy: { _count: { id: 'desc' } },
        take: 10,
      }),

      // Difficulty distribution
      prisma.interviewSession.groupBy({
        by: ['difficulty'],
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
      }),

      // Type distribution (BEHAVIORAL, TECHNICAL, SYSTEM_DESIGN, etc.)
      prisma.interviewSession.groupBy({
        by: ['type'],
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
      }),

      // Scores for score distribution buckets
      prisma.interviewSession.findMany({
        where: { createdAt: { gte: startDate, lte: endDate } },
        select: { score: true },
      }),

      // Pro vs Free user counts
      prisma.entitlement.count({ where: { feature: 'PREMIUM', status: 'ACTIVE' } }),
      prisma.user.count(),

      // Free user quotas usage
      prisma.userUsageQuota.aggregate({
        where: { periodKey: { startsWith: 'free' } },
        _avg: { interviewsUsed: true, resumeScansUsed: true, voiceSecondsUsed: true },
        _sum: { interviewsUsed: true, resumeScansUsed: true, voiceSecondsUsed: true },
      }),

      // Pro user quotas usage
      prisma.userUsageQuota.aggregate({
        where: { periodKey: { startsWith: 'sub' } },
        _avg: { interviewsUsed: true, resumeScansUsed: true, voiceSecondsUsed: true },
        _sum: { interviewsUsed: true, resumeScansUsed: true, voiceSecondsUsed: true },
      }),

      // Free interview sessions
      prisma.interviewSession.aggregate({
        where: {
          user: { entitlements: { none: { feature: 'PREMIUM', status: 'ACTIVE' } } },
          createdAt: { gte: startDate, lte: endDate },
        },
        _count: { id: true },
        _avg: { score: true },
      }),

      // Pro interview sessions
      prisma.interviewSession.aggregate({
        where: {
          user: { entitlements: { some: { feature: 'PREMIUM', status: 'ACTIVE' } } },
          createdAt: { gte: startDate, lte: endDate },
        },
        _count: { id: true },
        _avg: { score: true },
      }),

      // Conversion funnel stats
      prisma.subscription.count({ where: { createdAt: { gte: startDate, lte: endDate } } }),
      prisma.paymentTransaction.count({
        where: { status: 'CAPTURED', createdAt: { gte: startDate, lte: endDate } },
      }),
      prisma.subscription.count({ where: { status: 'ACTIVE' } }),
    ]);

    // Calculate score distribution
    const scoreBuckets = {
      under50: 0,
      fiftyTo69: 0,
      seventyTo84: 0,
      eightyFivePlus: 0,
    };
    for (const s of allSessions) {
      if (s.score < 50) scoreBuckets.under50++;
      else if (s.score < 70) scoreBuckets.fiftyTo69++;
      else if (s.score < 85) scoreBuckets.seventyTo84++;
      else scoreBuckets.eightyFivePlus++;
    }

    const freeUsersCount = Math.max(0, totalUsersCount - proUsersCount);

    return {
      engagement: {
        dau,
        wau,
        mau,
        dauToMauRatioPercent: mau > 0 ? Math.round((dau / mau) * 1000) / 10 : 0,
      },
      rolesPracticed: rolesStats.map((r: any) => ({
        role: r.role,
        interviewsCount: r._count.id,
        averageScore: Math.round(r._avg.score ?? 0),
      })),
      difficultyBreakdown: difficultyStats.map((d: any) => ({
        difficulty: d.difficulty,
        count: d._count.id,
      })),
      typeBreakdown: typeStats.map((t: any) => ({
        type: t.type,
        count: t._count.id,
      })),
      scoreDistribution: [
        { band: '0 - 49 (Needs Practice)', count: scoreBuckets.under50 },
        { band: '50 - 69 (Average)', count: scoreBuckets.fiftyTo69 },
        { band: '70 - 84 (Strong)', count: scoreBuckets.seventyTo84 },
        { band: '85 - 100 (Exceptional)', count: scoreBuckets.eightyFivePlus },
      ],
      freeVsProComparison: {
        freeUsers: freeUsersCount,
        proUsers: proUsersCount,
        freeInterviews: freeSessionsAgg._count.id,
        proInterviews: proSessionsAgg._count.id,
        freeAverageScore: Math.round(freeSessionsAgg._avg.score ?? 0),
        proAverageScore: Math.round(proSessionsAgg._avg.score ?? 0),
        freeAvgInterviewsPerUser:
          freeUsersCount > 0
            ? Math.round((freeSessionsAgg._count.id / freeUsersCount) * 10) / 10
            : 0,
        proAvgInterviewsPerUser:
          proUsersCount > 0
            ? Math.round((proSessionsAgg._count.id / proUsersCount) * 10) / 10
            : 0,
        freeTotalVoiceMinutes: Math.round((freeQuotasAgg._sum.voiceSecondsUsed ?? 0) / 60),
        proTotalVoiceMinutes: Math.round((proQuotasAgg._sum.voiceSecondsUsed ?? 0) / 60),
        freeTotalResumeScans: freeQuotasAgg._sum.resumeScansUsed ?? 0,
        proTotalResumeScans: proQuotasAgg._sum.resumeScansUsed ?? 0,
      },
      conversionFunnel: [
        { stage: 'Total Users', count: totalUsersCount, conversionPercent: 100 },
        {
          stage: 'Free Active Candidates',
          count: freeUsersCount,
          conversionPercent:
            totalUsersCount > 0 ? Math.round((freeUsersCount / totalUsersCount) * 100) : 0,
        },
        {
          stage: 'Checkout Initiated',
          count: subsCreatedCount,
          conversionPercent:
            freeUsersCount > 0 ? Math.round((subsCreatedCount / freeUsersCount) * 100) : 0,
        },
        {
          stage: 'Payment Captured',
          count: paymentsCapturedCount,
          conversionPercent:
            subsCreatedCount > 0
              ? Math.round((paymentsCapturedCount / subsCreatedCount) * 100)
              : 0,
        },
        {
          stage: 'Active Pro Subscriptions',
          count: activeSubsCount,
          conversionPercent:
            totalUsersCount > 0 ? Math.round((activeSubsCount / totalUsersCount) * 100) : 0,
        },
      ],
    };
  }
}

export const adminAnalyticsService = new AdminAnalyticsService();
