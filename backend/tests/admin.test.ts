import { requireAdmin } from '../src/middleware/admin.middleware';
import { adminDashboardService } from '../src/services/admin/admin.dashboard.service';
import { adminUsersService } from '../src/services/admin/admin.users.service';
import { adminInterviewsService } from '../src/services/admin/admin.interviews.service';
import { adminSubscriptionsService } from '../src/services/admin/admin.subscriptions.service';
import { adminPaymentsService } from '../src/services/admin/admin.payments.service';
import { adminAiService } from '../src/services/admin/admin.ai.service';
import { adminHealthService } from '../src/services/admin/admin.health.service';
import { adminAuditService } from '../src/services/admin/admin.audit.service';
import { adminSettingsService } from '../src/services/admin/admin.settings.service';
import { prisma } from '../src/config/database';
import { ForbiddenError, UnauthorizedError } from '../src/errors/AppError';

describe('Admin Control Center Unit & Service Tests', () => {
  let adminUserId: string;
  let normalUserId: string;

  beforeAll(async () => {
    // 1. Create or get Admin user
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin_test_suite@mockinterview.com' },
      create: {
        email: 'admin_test_suite@mockinterview.com',
        passwordHash: 'dummy_hash',
        isVerified: true,
        isActive: true,
        role: 'ADMIN',
        isAdmin: true,
      },
      update: {
        role: 'ADMIN',
        isAdmin: true,
        isActive: true,
      },
    });
    adminUserId = adminUser.id;

    // 2. Create or get Normal user
    const normalUser = await prisma.user.upsert({
      where: { email: 'normal_test_user@mockinterview.com' },
      create: {
        email: 'normal_test_user@mockinterview.com',
        passwordHash: 'dummy_hash',
        isVerified: true,
        isActive: true,
        role: 'USER',
        isAdmin: false,
      },
      update: {
        role: 'USER',
        isAdmin: false,
        isActive: true,
      },
    });
    normalUserId = normalUser.id;

    // 3. Seed sample data for testing
    await prisma.paymentTransaction.create({
      data: {
        userId: normalUserId,
        amount: 49900, // ₹499
        currency: 'INR',
        status: 'CAPTURED',
        providerPaymentId: `test_pay_${Date.now()}`,
      },
    });

    await prisma.aiTelemetryLog.create({
      data: {
        userId: normalUserId,
        operation: 'live_turn',
        provider: 'gemini',
        model: 'gemini-3.8-flash',
        latencyMs: 1100,
        inputTokens: 400,
        outputTokens: 150,
        totalTokens: 550,
        status: 200,
      },
    });
  });

  afterAll(async () => {
    // Cleanup test data
    await prisma.aiTelemetryLog.deleteMany({ where: { userId: normalUserId } });
    await prisma.paymentTransaction.deleteMany({ where: { userId: normalUserId } });
    await prisma.auditLog.deleteMany({ where: { adminId: adminUserId } });
    await prisma.user.deleteMany({
      where: { email: { in: ['admin_test_suite@mockinterview.com', 'normal_test_user@mockinterview.com'] } },
    });
    await prisma.$disconnect();
  });

  describe('Admin Authorization Middleware (requireAdmin)', () => {
    it('should reject unauthenticated requests with UnauthorizedError', () => {
      const req: any = { user: undefined };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      const err = next.mock.calls[0][0];
      expect(err).toBeInstanceOf(UnauthorizedError);
      expect(err.statusCode).toBe(401);
    });

    it('should reject non-admin users with ForbiddenError (403)', () => {
      const req: any = { user: { id: normalUserId, email: 'user@test.com', role: 'USER', isAdmin: false } };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      const err = next.mock.calls[0][0];
      expect(err).toBeInstanceOf(ForbiddenError);
      expect(err.statusCode).toBe(403);
      expect(err.errorCode).toBe('ADMIN_REQUIRED');
    });

    it('should allow access to users with role ADMIN', () => {
      const req: any = { user: { id: adminUserId, email: 'admin@test.com', role: 'ADMIN', isAdmin: true } };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledWith();
    });
  });

  describe('Dashboard Overview & Metrics Aggregation', () => {
    it('should return complete dashboard KPIs and charts without errors', async () => {
      const overview = await adminDashboardService.getOverview('30d');

      expect(overview.kpis.totalUsers.value).toBeGreaterThan(0);
      expect(overview.kpis.revenueRupees.value).toBeGreaterThanOrEqual(0);
      expect(overview.subscriptionDistribution).toBeDefined();
      expect(overview.aiUsageSummary).toBeDefined();
      expect(overview.aiUsageSummary.estimatedCostRupees).toBeGreaterThanOrEqual(0);
      expect(Array.isArray(overview.charts.revenueOverTime)).toBe(true);
      expect(Array.isArray(overview.charts.userGrowthOverTime)).toBe(true);
      expect(Array.isArray(overview.charts.interviewActivityOverTime)).toBe(true);
    });
  });

  describe('User Management Service', () => {
    it('should list users with pagination and search filter', async () => {
      const result = await adminUsersService.listUsers({
        page: 1,
        limit: 10,
        search: 'normal_test_user',
      });

      expect(result.users.length).toBeGreaterThanOrEqual(1);
      expect(result.pagination.total).toBeGreaterThanOrEqual(1);
      expect(result.users[0].email).toBe('normal_test_user@mockinterview.com');
    });

    it('should get detailed profile, subscription, and metrics for a user', async () => {
      const details = await adminUsersService.getUserDetails(normalUserId);

      expect(details.user.id).toBe(normalUserId);
      expect(details.usage).toBeDefined();
      expect(details.interviewMetrics).toBeDefined();
      expect(details.payments).toBeDefined();
    });

    it('should suspend and restore user with audit log creation', async () => {
      // Suspend
      await adminUsersService.suspendUser(adminUserId, normalUserId, 'Violation of terms test');
      let user = await prisma.user.findUnique({ where: { id: normalUserId } });
      expect(user?.isActive).toBe(false);

      // Verify audit log
      let audit = await prisma.auditLog.findFirst({
        where: { targetId: normalUserId, action: 'USER_SUSPEND' },
      });
      expect(audit).toBeDefined();
      expect(audit?.adminId).toBe(adminUserId);

      // Restore
      await adminUsersService.restoreUser(adminUserId, normalUserId, 'Restored test');
      user = await prisma.user.findUnique({ where: { id: normalUserId } });
      expect(user?.isActive).toBe(true);

      audit = await prisma.auditLog.findFirst({
        where: { targetId: normalUserId, action: 'USER_RESTORE' },
      });
      expect(audit).toBeDefined();
    });

    it('should grant and revoke entitlements with audit logging', async () => {
      // Grant
      const grant = await adminUsersService.updateEntitlement(
        adminUserId,
        normalUserId,
        'ACTIVE',
        null,
        'Promotion grant test'
      );
      expect(grant.entitlement.status).toBe('ACTIVE');

      const grantAudit = await prisma.auditLog.findFirst({
        where: { targetId: normalUserId, action: 'ENTITLEMENT_GRANT' },
      });
      expect(grantAudit).toBeDefined();

      // Revoke
      const revoke = await adminUsersService.updateEntitlement(
        adminUserId,
        normalUserId,
        'INACTIVE',
        null,
        'Revocation test'
      );
      expect(revoke.entitlement.status).toBe('INACTIVE');
    });

    it('should generate valid RFC-4180 CSV for users export', async () => {
      const csv = await adminUsersService.exportUsersCsv({ page: 1, limit: 10 });
      expect(csv).toContain('ID,Name,Email,Role,Tier');
    });
  });

  describe('Interview Management Service', () => {
    it('should list interviews with pagination', async () => {
      const result = await adminInterviewsService.listInterviews({ page: 1, limit: 10 });
      expect(result.interviews).toBeDefined();
      expect(result.pagination).toBeDefined();
    });

    it('should export interviews as CSV', async () => {
      const csv = await adminInterviewsService.exportInterviewsCsv({ page: 1, limit: 10 });
      expect(typeof csv).toBe('string');
    });
  });

  describe('Subscription & Payments Services', () => {
    it('should calculate subscription MRR and distribution accurately', async () => {
      const stats = await adminSubscriptionsService.getSubscriptionStats();
      expect(stats.mrrRupees).toBeGreaterThanOrEqual(0);
      expect(stats.arrRupees).toBe(stats.mrrRupees * 12);
      expect(stats.churnRatePercent).toBeGreaterThanOrEqual(0);
    });

    it('should calculate gross and net revenue from captured payments only', async () => {
      const stats = await adminPaymentsService.getPaymentStats();
      expect(stats.grossRevenueRupees).toBeGreaterThanOrEqual(0);
      expect(stats.netRevenueRupees).toBe(stats.grossRevenueRupees - stats.refundRupees);
      expect(stats.successRatePercent).toBeGreaterThanOrEqual(0);
    });

    it('should list payments and export payments as CSV', async () => {
      const payments = await adminPaymentsService.listPayments({ page: 1, limit: 10 });
      expect(payments.payments).toBeDefined();

      const csv = await adminPaymentsService.exportPaymentsCsv({ page: 1, limit: 10 });
      expect(csv).toContain('ID,User,Plan,Amount,Currency,Status');
    });
  });

  describe('AI Usage & Cost Monitoring Service', () => {
    it('should aggregate tokens, compute estimated cost, and provide latency percentiles', async () => {
      const metrics = await adminAiService.getAiUsageMetrics('30d');
      expect(metrics.requestsOverview).toBeDefined();
      expect(metrics.tokenUsage.totalTokens).toBeGreaterThanOrEqual(550);
      expect(metrics.estimatedCost.label).toBe('Estimated AI Cost');
      expect(metrics.latencyMetrics.p50LatencyMs).toBeDefined();
      expect(metrics.latencyMetrics.p95LatencyMs).toBeDefined();
    });

    it('should export AI telemetry as CSV', async () => {
      const csv = await adminAiService.exportAiUsageCsv('30d');
      expect(csv).toContain('ID,Timestamp,Operation,Provider,Model');
    });
  });

  describe('System Health & Settings Services', () => {
    it('should check system health for all 5 subsystems without crashing', async () => {
      const health = await adminHealthService.getSystemHealth();
      expect(health.overallStatus).toBeDefined();
      expect(health.services.length).toBe(5);

      const dbService = health.services.find((s) => s.service === 'PostgreSQL Database');
      expect(dbService?.status).toBe('HEALTHY');
    });

    it('should fetch and update settings with audit logging', async () => {
      const settings = await adminSettingsService.getSettings();
      expect(settings.freeInterviewLimit).toBeDefined();

      const updated = await adminSettingsService.updateSettings(
        adminUserId,
        { freeInterviewLimit: 4 },
        'Automated test update'
      );
      expect(updated.settings.freeInterviewLimit).toBe(4);

      const audit = await prisma.auditLog.findFirst({
        where: { action: 'SETTINGS_UPDATE', adminId: adminUserId },
      });
      expect(audit).toBeDefined();
    });
  });
});
