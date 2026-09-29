import { prisma } from '../../config/database';
import { parseDateRange } from './admin.helper';

export class AdminResumesService {
  async getResumeAnalytics(range?: string, customStart?: string, customEnd?: string) {
    const dates = parseDateRange(range, customStart, customEnd);
    const { startDate, endDate } = dates;

    const [
      totalCount,
      successCount,
      failedCount,
      durationAgg,
      failureReasons,
      recentParses,
    ] = await Promise.all([
      prisma.resumeParseLog.count({
        where: { createdAt: { gte: startDate, lte: endDate } },
      }),
      prisma.resumeParseLog.count({
        where: { status: 'SUCCESS', createdAt: { gte: startDate, lte: endDate } },
      }),
      prisma.resumeParseLog.count({
        where: { status: 'FAILED', createdAt: { gte: startDate, lte: endDate } },
      }),
      prisma.resumeParseLog.aggregate({
        where: { status: 'SUCCESS', createdAt: { gte: startDate, lte: endDate } },
        _avg: { durationMs: true },
      }),
      prisma.resumeParseLog.groupBy({
        by: ['errorReason'],
        where: { status: 'FAILED', createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
      }),
      prisma.resumeParseLog.findMany({
        where: { createdAt: { gte: startDate, lte: endDate } },
        take: 20,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const successRatePercent =
      totalCount > 0 ? Math.round((successCount / totalCount) * 1000) / 10 : 100;

    return {
      totalUploads: totalCount,
      successfulParses: successCount,
      failedParses: failedCount,
      successRatePercent,
      averageParsingTimeMs: Math.round(durationAgg._avg.durationMs ?? 0),
      failureReasons: failureReasons.map((r: any) => ({
        reason: r.errorReason || 'UNKNOWN',
        count: r._count.id,
      })),
      recentUploads: recentParses.map((p: any) => ({
        id: p.id,
        userId: p.userId,
        fileName: p.fileName,
        fileSizeBytes: p.fileSize,
        fileSizeKb: Math.round(p.fileSize / 1024),
        status: p.status,
        errorReason: p.errorReason,
        durationMs: p.durationMs,
        createdAt: p.createdAt.toISOString(),
      })),
    };
  }
}

export const adminResumesService = new AdminResumesService();
