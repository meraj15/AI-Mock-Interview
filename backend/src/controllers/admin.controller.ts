import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../types/auth.types';
import { adminDashboardService } from '../services/admin/admin.dashboard.service';
import { adminUsersService } from '../services/admin/admin.users.service';
import { adminInterviewsService } from '../services/admin/admin.interviews.service';
import { adminSubscriptionsService } from '../services/admin/admin.subscriptions.service';
import { adminPaymentsService } from '../services/admin/admin.payments.service';
import { adminAiService } from '../services/admin/admin.ai.service';
import { adminAnalyticsService } from '../services/admin/admin.analytics.service';
import { adminResumesService } from '../services/admin/admin.resumes.service';
import { adminPlansService } from '../services/admin/admin.plans.service';
import { adminHealthService } from '../services/admin/admin.health.service';
import { adminAuditService } from '../services/admin/admin.audit.service';
import { adminSettingsService } from '../services/admin/admin.settings.service';
import { adminAppUpdatesService } from '../services/admin/admin.app-updates.service';
import { createAppUpdateSchema, updateAppUpdateSchema } from '../validators/app-update.validator';

export const adminController = {
  // ── Dashboard Overview ───────────────────────────────────────────────────────
  async getDashboardOverview(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const range = typeof req.query.range === 'string' ? req.query.range : undefined;
      const customStart = typeof req.query.customStart === 'string' ? req.query.customStart : undefined;
      const customEnd = typeof req.query.customEnd === 'string' ? req.query.customEnd : undefined;

      const overview = await adminDashboardService.getOverview(range, customStart, customEnd);
      res.status(200).json({ success: true, data: overview });
    } catch (err) {
      next(err);
    }
  },

  // ── Users Management ────────────────────────────────────────────────────────
  async listUsers(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = req.query as any;
      const result = await adminUsersService.listUsers({
        page: query.page ? Number(query.page) : undefined,
        limit: query.limit ? Number(query.limit) : undefined,
        search: typeof query.search === 'string' ? query.search : undefined,
        tier: query.tier,
        status: query.status,
        highUsage: query.highUsage === 'true',
        paymentFailed: query.paymentFailed === 'true',
        sort: query.sort,
      });
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async getUserDetails(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const details = await adminUsersService.getUserDetails(userId);
      res.status(200).json({ success: true, data: details });
    } catch (err) {
      next(err);
    }
  },

  async suspendUser(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const { reason } = req.body;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminUsersService.suspendUser(adminId, userId, reason, ip);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async restoreUser(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const { reason } = req.body;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminUsersService.restoreUser(adminId, userId, reason, ip);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async updateUserEntitlement(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const userId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const { status, expiresAt, reason } = req.body;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminUsersService.updateEntitlement(
        adminId,
        userId,
        status,
        expiresAt ? new Date(expiresAt) : null,
        reason,
        ip
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async exportUsersCsv(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const csv = await adminUsersService.exportUsersCsv(req.query as any);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="users-export.csv"');
      res.status(200).send(csv);
    } catch (err) {
      next(err);
    }
  },

  // ── Interview Management ───────────────────────────────────────────────────
  async listInterviews(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await adminInterviewsService.listInterviews(req.query as any);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async getInterviewDetail(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const interviewId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const details = await adminInterviewsService.getInterviewDetail(interviewId);
      res.status(200).json({ success: true, data: details });
    } catch (err) {
      next(err);
    }
  },

  async exportInterviewsCsv(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const csv = await adminInterviewsService.exportInterviewsCsv(req.query as any);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="interviews-export.csv"');
      res.status(200).send(csv);
    } catch (err) {
      next(err);
    }
  },

  // ── Subscriptions Management ───────────────────────────────────────────────
  async listSubscriptions(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await adminSubscriptionsService.listSubscriptions(req.query as any);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async getSubscriptionStats(_req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await adminSubscriptionsService.getSubscriptionStats();
      res.status(200).json({ success: true, data: stats });
    } catch (err) {
      next(err);
    }
  },

  async cancelSubscription(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const subId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const { reason } = req.body;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminSubscriptionsService.cancelSubscription(adminId, subId, reason, ip);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  // ── Payments Management ────────────────────────────────────────────────────
  async listPayments(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await adminPaymentsService.listPayments(req.query as any);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async getPaymentStats(_req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await adminPaymentsService.getPaymentStats();
      res.status(200).json({ success: true, data: stats });
    } catch (err) {
      next(err);
    }
  },

  async listWebhooks(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await adminPaymentsService.listWebhooks(page, limit);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async exportPaymentsCsv(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const csv = await adminPaymentsService.exportPaymentsCsv(req.query as any);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="payments-export.csv"');
      res.status(200).send(csv);
    } catch (err) {
      next(err);
    }
  },

  // ── AI Usage Monitoring ────────────────────────────────────────────────────
  async getAiUsage(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const range = typeof req.query.range === 'string' ? req.query.range : undefined;
      const customStart = typeof req.query.customStart === 'string' ? req.query.customStart : undefined;
      const customEnd = typeof req.query.customEnd === 'string' ? req.query.customEnd : undefined;

      const metrics = await adminAiService.getAiUsageMetrics(range, customStart, customEnd);
      res.status(200).json({ success: true, data: metrics });
    } catch (err) {
      next(err);
    }
  },

  async exportAiUsageCsv(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const range = typeof req.query.range === 'string' ? req.query.range : undefined;
      const csv = await adminAiService.exportAiUsageCsv(range);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="ai-usage-export.csv"');
      res.status(200).send(csv);
    } catch (err) {
      next(err);
    }
  },

  // ── Analytics ──────────────────────────────────────────────────────────────
  async getAnalytics(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const range = typeof req.query.range === 'string' ? req.query.range : undefined;
      const customStart = typeof req.query.customStart === 'string' ? req.query.customStart : undefined;
      const customEnd = typeof req.query.customEnd === 'string' ? req.query.customEnd : undefined;

      const analytics = await adminAnalyticsService.getAnalytics(range, customStart, customEnd);
      res.status(200).json({ success: true, data: analytics });
    } catch (err) {
      next(err);
    }
  },

  // ── Resumes Analytics ──────────────────────────────────────────────────────
  async getResumeAnalytics(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const range = typeof req.query.range === 'string' ? req.query.range : undefined;
      const customStart = typeof req.query.customStart === 'string' ? req.query.customStart : undefined;
      const customEnd = typeof req.query.customEnd === 'string' ? req.query.customEnd : undefined;

      const result = await adminResumesService.getResumeAnalytics(range, customStart, customEnd);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  },

  // ── Plans Management ───────────────────────────────────────────────────────
  async listPlans(_req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const plans = await adminPlansService.listPlans();
      res.status(200).json({ success: true, data: plans });
    } catch (err) {
      next(err);
    }
  },

  async updatePlan(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const planId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminPlansService.updatePlan(adminId, planId, req.body, ip);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  // ── System Health ──────────────────────────────────────────────────────────
  async getSystemHealth(_req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const health = await adminHealthService.getSystemHealth();
      res.status(200).json({ success: true, data: health });
    } catch (err) {
      next(err);
    }
  },

  // ── Audit Logs ─────────────────────────────────────────────────────────────
  async listAuditLogs(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await adminAuditService.listAuditLogs(req.query as any);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  // ── Settings ───────────────────────────────────────────────────────────────
  async getSettings(_req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const settings = await adminSettingsService.getSettings();
      res.status(200).json({ success: true, data: settings });
    } catch (err) {
      next(err);
    }
  },

  async updateSettings(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const { settings, reason } = req.body;
      const ip = req.ip || req.socket.remoteAddress;
      const result = await adminSettingsService.updateSettings(adminId, settings, reason, ip);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  // ── App Updates Management ─────────────────────────────────────────────────
  async listAppUpdates(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await adminAppUpdatesService.listAppUpdates(req.query as any);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  async getAppUpdate(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const update = await adminAppUpdatesService.getAppUpdateById(id);
      res.status(200).json({ success: true, data: update });
    } catch (err) {
      next(err);
    }
  },

  async createAppUpdate(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const validated = createAppUpdateSchema.parse(req.body);
      const ip = req.ip || req.socket.remoteAddress;
      const created = await adminAppUpdatesService.createAppUpdate(adminId, validated as any, ip);
      res.status(201).json({ success: true, data: created });
    } catch (err) {
      next(err);
    }
  },

  async updateAppUpdate(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const validated = updateAppUpdateSchema.parse(req.body);
      const ip = req.ip || req.socket.remoteAddress;
      const updated = await adminAppUpdatesService.updateAppUpdate(adminId, id, validated as any, ip);
      res.status(200).json({ success: true, data: updated });
    } catch (err) {
      next(err);
    }
  },

  async publishAppUpdate(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const ip = req.ip || req.socket.remoteAddress;
      const published = await adminAppUpdatesService.publishAppUpdate(adminId, id, ip);
      res.status(200).json({ success: true, data: published });
    } catch (err) {
      next(err);
    }
  },

  async disableAppUpdate(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminId = req.user!.id;
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const ip = req.ip || req.socket.remoteAddress;
      const disabled = await adminAppUpdatesService.disableAppUpdate(adminId, id, ip);
      res.status(200).json({ success: true, data: disabled });
    } catch (err) {
      next(err);
    }
  },
};
