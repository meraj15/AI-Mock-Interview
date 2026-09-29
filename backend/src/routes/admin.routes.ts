import { Router } from 'express';
import { adminController } from '../controllers/admin.controller';
import { authMiddleware } from '../middleware/auth.middleware';
import { requireAdmin } from '../middleware/admin.middleware';

const router = Router();

// ── Strict Security ──────────────────────────────────────────────────────────
// Both authentication and ADMIN role verification are required on all routes.
router.use(authMiddleware as any, requireAdmin as any);

// ── Dashboard Overview ───────────────────────────────────────────────────────
router.get('/dashboard', adminController.getDashboardOverview as any);

// ── Users Management ────────────────────────────────────────────────────────
router.get('/users', adminController.listUsers as any);
router.get('/users/export', adminController.exportUsersCsv as any);
router.get('/users/:id', adminController.getUserDetails as any);
router.post('/users/:id/suspend', adminController.suspendUser as any);
router.post('/users/:id/restore', adminController.restoreUser as any);
router.post('/users/:id/entitlement', adminController.updateUserEntitlement as any);

// ── Interview Management ───────────────────────────────────────────────────
router.get('/interviews', adminController.listInterviews as any);
router.get('/interviews/export', adminController.exportInterviewsCsv as any);
router.get('/interviews/:id', adminController.getInterviewDetail as any);

// ── Subscriptions Management ───────────────────────────────────────────────
router.get('/subscriptions', adminController.listSubscriptions as any);
router.get('/subscriptions/stats', adminController.getSubscriptionStats as any);
router.post('/subscriptions/:id/cancel', adminController.cancelSubscription as any);

// ── Payments Management ────────────────────────────────────────────────────
router.get('/payments', adminController.listPayments as any);
router.get('/payments/stats', adminController.getPaymentStats as any);
router.get('/payments/export', adminController.exportPaymentsCsv as any);
router.get('/webhooks', adminController.listWebhooks as any);

// ── AI Usage Monitoring ────────────────────────────────────────────────────
router.get('/ai-usage', adminController.getAiUsage as any);
router.get('/ai-usage/export', adminController.exportAiUsageCsv as any);

// ── Analytics ──────────────────────────────────────────────────────────────
router.get('/analytics', adminController.getAnalytics as any);

// ── Resumes Analytics ──────────────────────────────────────────────────────
router.get('/resumes', adminController.getResumeAnalytics as any);

// ── Plans Management ───────────────────────────────────────────────────────
router.get('/plans', adminController.listPlans as any);
router.put('/plans/:id', adminController.updatePlan as any);

// ── System Health ──────────────────────────────────────────────────────────
router.get('/system-health', adminController.getSystemHealth as any);

// ── Audit Logs ─────────────────────────────────────────────────────────────
router.get('/audit-logs', adminController.listAuditLogs as any);

// ── Settings ───────────────────────────────────────────────────────────────
router.get('/settings', adminController.getSettings as any);
router.put('/settings', adminController.updateSettings as any);

export default router;
