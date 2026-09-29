import { prisma } from '../../config/database';
import { config } from '../../config';

export interface ServiceHealthStatus {
  service: string;
  status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  latencyMs: number;
  details?: Record<string, any>;
  lastChecked: string;
}

export class AdminHealthService {
  async getSystemHealth(): Promise<{
    overallStatus: 'HEALTHY' | 'DEGRADED' | 'DOWN';
    uptimeSecs: number;
    timestamp: string;
    services: ServiceHealthStatus[];
  }> {
    const timestamp = new Date().toISOString();
    const services: ServiceHealthStatus[] = [];

    // 1. API Health
    const apiStart = Date.now();
    const mem = process.memoryUsage();
    services.push({
      service: 'API Server',
      status: 'HEALTHY',
      latencyMs: Date.now() - apiStart,
      details: {
        uptime: Math.round(process.uptime()),
        nodeVersion: process.version,
        memoryRssMb: Math.round(mem.rss / (1024 * 1024)),
        memoryHeapUsedMb: Math.round(mem.heapUsed / (1024 * 1024)),
      },
      lastChecked: timestamp,
    });

    // 2. Database Health (SELECT 1 query ping)
    const dbStart = Date.now();
    try {
      await prisma.$queryRaw`SELECT 1`;
      services.push({
        service: 'PostgreSQL Database',
        status: 'HEALTHY',
        latencyMs: Date.now() - dbStart,
        details: { connection: 'active', pool: 'healthy' },
        lastChecked: timestamp,
      });
    } catch (dbErr: any) {
      services.push({
        service: 'PostgreSQL Database',
        status: 'DOWN',
        latencyMs: Date.now() - dbStart,
        details: { error: dbErr?.message || 'Database connection error' },
        lastChecked: timestamp,
      });
    }

    // 3. Gemini AI Service (Lightweight: check credentials and telemetry/circuit health, no expensive API calls)
    const geminiStart = Date.now();
    const hasGeminiKey = Boolean(config.gemini.apiKey && config.gemini.apiKey.length > 5);
    const recentAiErrors = await prisma.aiTelemetryLog.count({
      where: {
        createdAt: { gte: new Date(Date.now() - 15 * 60 * 1000) },
        status: { gte: 500 },
      },
    });

    const geminiStatus: 'HEALTHY' | 'DEGRADED' | 'DOWN' = !hasGeminiKey
      ? 'DOWN'
      : recentAiErrors > 5
      ? 'DEGRADED'
      : 'HEALTHY';

    services.push({
      service: 'Gemini AI',
      status: geminiStatus,
      latencyMs: Date.now() - geminiStart,
      details: {
        configured: hasGeminiKey,
        primaryModel: config.ai.livePrimaryModel,
        fallbackModel: config.ai.fallbackModel,
        recentErrorsLast15m: recentAiErrors,
      },
      lastChecked: timestamp,
    });

    // 4. Razorpay Payment Gateway
    const rzpStart = Date.now();
    const hasRzpKey = Boolean(config.razorpay.keyId && config.razorpay.keySecret);
    const hasWebhook = Boolean(config.razorpay.webhookSecret);
    services.push({
      service: 'Razorpay Gateway',
      status: hasRzpKey ? 'HEALTHY' : 'DEGRADED',
      latencyMs: Date.now() - rzpStart,
      details: {
        configured: hasRzpKey,
        webhookConfigured: hasWebhook,
        mode: config.razorpay.isTestMode ? 'TEST' : 'LIVE',
      },
      lastChecked: timestamp,
    });

    // 5. Brevo Email Service
    const emailStart = Date.now();
    const hasEmailAuth = Boolean(config.email.smtpUser && config.email.smtpPassword);
    services.push({
      service: 'Email (SMTP)',
      status: hasEmailAuth ? 'HEALTHY' : 'DEGRADED',
      latencyMs: Date.now() - emailStart,
      details: {
        host: config.email.smtpHost,
        port: config.email.smtpPort,
        configured: hasEmailAuth,
      },
      lastChecked: timestamp,
    });

    const isAnyDown = services.some((s) => s.status === 'DOWN');
    const isAnyDegraded = services.some((s) => s.status === 'DEGRADED');
    const overallStatus = isAnyDown ? 'DOWN' : isAnyDegraded ? 'DEGRADED' : 'HEALTHY';

    return {
      overallStatus,
      uptimeSecs: Math.round(process.uptime()),
      timestamp,
      services,
    };
  }
}

export const adminHealthService = new AdminHealthService();
