import { prisma } from '../../config/database';
import { parseDateRange, estimateAiCostInPaise, convertToCsv } from './admin.helper';

export class AdminAiService {
  async getAiUsageMetrics(range?: string, customStart?: string, customEnd?: string) {
    const dates = parseDateRange(range, customStart, customEnd);
    const { startDate, endDate } = dates;
    const now = new Date();

    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const sevenDaysStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const [
      requestsToday,
      requests7d,
      requests30d,
      overallAgg,
      logsByOperation,
      recentErrors,
      errorCategoryCounts,
      allLatencies,
    ] = await Promise.all([
      // Requests today
      prisma.aiTelemetryLog.count({ where: { createdAt: { gte: todayStart } } }),
      // Requests 7 days
      prisma.aiTelemetryLog.count({ where: { createdAt: { gte: sevenDaysStart } } }),
      // Requests 30 days
      prisma.aiTelemetryLog.count({ where: { createdAt: { gte: thirtyDaysStart } } }),

      // Overall aggregate for selected date range
      prisma.aiTelemetryLog.aggregate({
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
        _sum: { inputTokens: true, outputTokens: true, totalTokens: true },
        _avg: {
          latencyMs: true,
          promptBuildMs: true,
          aiLatencyMs: true,
          parseMs: true,
          dbMs: true,
          totalLatencyMs: true,
        },
      }),

      // Breakdown by operation
      prisma.aiTelemetryLog.groupBy({
        by: ['operation'],
        where: { createdAt: { gte: startDate, lte: endDate } },
        _count: { id: true },
        _sum: { inputTokens: true, outputTokens: true, totalTokens: true, retryCount: true },
        _avg: { latencyMs: true },
      }),

      // Recent errors (status >= 400)
      prisma.aiTelemetryLog.findMany({
        where: {
          createdAt: { gte: startDate, lte: endDate },
          status: { gte: 400 },
        },
        take: 20,
        orderBy: { createdAt: 'desc' },
      }),

      // Error category counts
      prisma.aiTelemetryLog.groupBy({
        by: ['errorCategory'],
        where: {
          createdAt: { gte: startDate, lte: endDate },
          status: { gte: 400 },
        },
        _count: { id: true },
      }),

      // Latencies list for accurate P50 / P95 calculation
      prisma.aiTelemetryLog.findMany({
        where: { createdAt: { gte: startDate, lte: endDate } },
        select: { latencyMs: true },
        orderBy: { latencyMs: 'asc' },
      }),
    ]);

    // Calculate P50 and P95 latency
    let p50LatencyMs = 0;
    let p95LatencyMs = 0;
    if (allLatencies.length > 0) {
      const p50Index = Math.floor(allLatencies.length * 0.5);
      const p95Index = Math.floor(allLatencies.length * 0.95);
      p50LatencyMs = allLatencies[p50Index].latencyMs;
      p95LatencyMs = allLatencies[p95Index].latencyMs;
    }

    const inputTokensTotal = overallAgg._sum.inputTokens ?? 0;
    const outputTokensTotal = overallAgg._sum.outputTokens ?? 0;
    const totalTokens = overallAgg._sum.totalTokens ?? (inputTokensTotal + outputTokensTotal);

    const costEstimation = estimateAiCostInPaise(inputTokensTotal, outputTokensTotal);

    // Format operation breakdown
    const operationsBreakdown = await Promise.all(
      logsByOperation.map(async (op: any) => {
        const inputT = op._sum.inputTokens ?? 0;
        const outputT = op._sum.outputTokens ?? 0;
        const cost = estimateAiCostInPaise(inputT, outputT);

        const opErrorsCount = await prisma.aiTelemetryLog.count({
          where: {
            operation: op.operation,
            createdAt: { gte: startDate, lte: endDate },
            status: { gte: 400 },
          },
        });

        // Get P95 for this operation
        const opLatencies = await prisma.aiTelemetryLog.findMany({
          where: {
            operation: op.operation,
            createdAt: { gte: startDate, lte: endDate },
          },
          select: { latencyMs: true },
          orderBy: { latencyMs: 'asc' },
        });
        const opP95 =
          opLatencies.length > 0
            ? opLatencies[Math.floor(opLatencies.length * 0.95)].latencyMs
            : 0;

        return {
          operation: op.operation,
          requests: op._count.id,
          inputTokens: inputT,
          outputTokens: outputT,
          totalTokens: op._sum.totalTokens ?? (inputT + outputT),
          avgLatencyMs: Math.round(op._avg.latencyMs ?? 0),
          p95LatencyMs: opP95,
          retriesCount: op._sum.retryCount ?? 0,
          errorCount: opErrorsCount,
          estimatedCostRupees: Math.round(cost.totalCostPaise / 100),
        };
      })
    );

    return {
      dateRange: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
        label: dates.label,
      },
      requestsOverview: {
        today: requestsToday,
        last7Days: requests7d,
        last30Days: requests30d,
        selectedRange: overallAgg._count.id,
      },
      tokenUsage: {
        inputTokens: inputTokensTotal,
        outputTokens: outputTokensTotal,
        totalTokens,
      },
      estimatedCost: {
        currency: 'INR',
        label: 'Estimated AI Cost',
        inputCostRupees: Math.round(costEstimation.inputCostPaise / 100),
        outputCostRupees: Math.round(costEstimation.outputCostPaise / 100),
        totalCostRupees: Math.round(costEstimation.totalCostPaise / 100),
      },
      latencyMetrics: {
        averageLatencyMs: Math.round(overallAgg._avg.latencyMs ?? 0),
        p50LatencyMs,
        p95LatencyMs,
        avgPromptBuildMs: Math.round(overallAgg._avg.promptBuildMs ?? 0),
        avgAiLatencyMs: Math.round(overallAgg._avg.aiLatencyMs ?? 0),
        avgParseMs: Math.round(overallAgg._avg.parseMs ?? 0),
        avgDbMs: Math.round(overallAgg._avg.dbMs ?? 0),
        avgTotalLatencyMs: Math.round(overallAgg._avg.totalLatencyMs ?? 0),
      },
      operations: operationsBreakdown,
      errorCategories: errorCategoryCounts.map((c: any) => ({
        category: c.errorCategory || 'OTHER',
        count: c._count.id,
      })),
      recentErrors: recentErrors.map((err: any) => ({
        id: err.id,
        timestamp: err.createdAt.toISOString(),
        operation: err.operation,
        provider: err.provider,
        model: err.model,
        httpStatus: err.status,
        errorCategory: err.errorCategory || 'UNKNOWN',
        latencyMs: err.latencyMs,
        retryCount: err.retryCount,
        sessionId: err.sessionId,
        errorMessage: err.errorMessage || 'Unknown AI error',
      })),
    };
  }

  async exportAiUsageCsv(range?: string): Promise<string> {
    const dates = parseDateRange(range);
    const logs = await prisma.aiTelemetryLog.findMany({
      where: { createdAt: { gte: dates.startDate, lte: dates.endDate } },
      take: 1000,
      orderBy: { createdAt: 'desc' },
    });

    const rows = logs.map((l: any) => ({
      ID: l.id,
      Timestamp: l.createdAt.toISOString(),
      Operation: l.operation,
      Provider: l.provider,
      Model: l.model,
      'Latency (ms)': l.latencyMs,
      'Input Tokens': l.inputTokens,
      'Output Tokens': l.outputTokens,
      'Total Tokens': l.totalTokens,
      Status: l.status,
      'Error Category': l.errorCategory ?? 'NONE',
      'Retry Count': l.retryCount,
      'Session ID': l.sessionId ?? 'N/A',
    }));

    return convertToCsv(rows);
  }
}

export const adminAiService = new AdminAiService();
