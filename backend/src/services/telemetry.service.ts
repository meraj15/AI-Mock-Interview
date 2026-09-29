import { prisma } from '../config/database';
import { logger } from '../utils/logger';

export interface RecordAiTelemetryInput {
  sessionId?: string | null;
  userId?: string | null;
  operation: string;
  provider: string;
  model: string;
  latencyMs: number;
  promptBuildMs?: number | null;
  aiLatencyMs?: number | null;
  parseMs?: number | null;
  dbMs?: number | null;
  totalLatencyMs?: number | null;
  attemptCount?: number;
  retryCount?: number;
  retryReason?: string | null;
  tokenUsage?: {
    inputTokens?: number;
    outputTokens?: number;
    totalTokens?: number;
  };
  status?: number;
  errorCategory?: string | null;
  errorMessage?: string | null;
  degraded?: boolean;
}

export interface RecordResumeParseInput {
  userId?: string;
  fileName: string;
  fileSize: number;
  status: 'SUCCESS' | 'FAILED';
  errorReason?: string;
  durationMs: number;
}

export interface CreateAuditLogInput {
  adminId: string;
  action: string;
  targetType: string;
  targetId?: string;
  previousValue?: any;
  newValue?: any;
  reason?: string;
  ipAddress?: string;
}

export class TelemetryService {
  /**
   * Records AI execution telemetry into PostgreSQL asynchronously.
   * Fire-and-forget: never throws or disrupts normal AI execution.
   */
  async recordAiTelemetry(data: RecordAiTelemetryInput): Promise<void> {
    try {
      await prisma.aiTelemetryLog.create({
        data: {
          sessionId: data.sessionId ?? null,
          userId: data.userId ?? null,
          operation: data.operation,
          provider: data.provider,
          model: data.model,
          latencyMs: Math.round(data.latencyMs),
          promptBuildMs: data.promptBuildMs ? Math.round(data.promptBuildMs) : null,
          aiLatencyMs: data.aiLatencyMs ? Math.round(data.aiLatencyMs) : null,
          parseMs: data.parseMs ? Math.round(data.parseMs) : null,
          dbMs: data.dbMs ? Math.round(data.dbMs) : null,
          totalLatencyMs: data.totalLatencyMs ? Math.round(data.totalLatencyMs) : null,
          attemptCount: data.attemptCount ?? 1,
          retryCount: data.retryCount ?? 0,
          retryReason: data.retryReason ?? null,
          inputTokens: data.tokenUsage?.inputTokens ?? 0,
          outputTokens: data.tokenUsage?.outputTokens ?? 0,
          totalTokens: data.tokenUsage?.totalTokens ?? 0,
          status: data.status ?? 200,
          errorCategory: data.errorCategory ?? null,
          errorMessage: data.errorMessage ? data.errorMessage.slice(0, 500) : null,
          degraded: data.degraded ?? false,
        },
      });
    } catch (err: any) {
      logger.warn(`Failed to persist AI telemetry log: ${err.message}`);
    }
  }

  /**
   * Records resume upload & parsing status.
   */
  async recordResumeParse(data: RecordResumeParseInput): Promise<void> {
    try {
      await prisma.resumeParseLog.create({
        data: {
          userId: data.userId ?? null,
          fileName: data.fileName,
          fileSize: data.fileSize,
          status: data.status,
          errorReason: data.errorReason ?? null,
          durationMs: Math.round(data.durationMs),
        },
      });
    } catch (err: any) {
      logger.warn(`Failed to persist resume parse log: ${err.message}`);
    }
  }

  /**
   * Records privileged administrator action into immutable audit log.
   */
  async recordAuditLog(data: CreateAuditLogInput): Promise<void> {
    try {
      await prisma.auditLog.create({
        data: {
          adminId: data.adminId,
          action: data.action,
          targetType: data.targetType,
          targetId: data.targetId ?? null,
          previousValue: data.previousValue ?? undefined,
          newValue: data.newValue ?? undefined,
          reason: data.reason ?? null,
          ipAddress: data.ipAddress ?? null,
        },
      });
    } catch (err: any) {
      logger.error(`CRITICAL: Failed to write audit log: ${err.message}`, { data });
    }
  }
}

export const telemetryService = new TelemetryService();
