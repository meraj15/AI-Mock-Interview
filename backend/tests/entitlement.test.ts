/**
 * entitlement.test.ts
 *
 * Comprehensive unit tests for EntitlementService and quota enforcement.
 */
import { entitlementService, FREE_LIMITS, PRO_LIMITS } from '../src/services/entitlement.service';
import { subscriptionRepository } from '../src/repositories/subscription.repository';

jest.mock('../src/repositories/subscription.repository', () => ({
  subscriptionRepository: {
    hasActivePremiumEntitlement: jest.fn(),
    findActiveSubscriptionForUser: jest.fn(),
    findUsageQuota: jest.fn(),
    incrementInterviewUsage: jest.fn(),
    incrementResumeScanUsage: jest.fn(),
  },
}));

jest.mock('../src/utils/logger', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

const repo = subscriptionRepository as jest.Mocked<typeof subscriptionRepository>;

describe('EntitlementService — Free vs Pro Entitlements & Quotas', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('FREE Tier Entitlements', () => {
    it('resolves FREE tier limits when user has no active subscription', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-1',
        userId: 'user-free-1',
        periodKey: 'free_2026-09',
        interviewsUsed: 0,
        resumeScansUsed: 0,
        voiceSecondsUsed: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-free-1');

      expect(entitlement.tier).toBe('FREE');
      expect(entitlement.isPremium).toBe(false);
      expect(entitlement.interviewsLimit).toBe(2);
      expect(entitlement.interviewsUsed).toBe(0);
      expect(entitlement.interviewsRemaining).toBe(2);
      expect(entitlement.maxQuestionsPerSession).toBe(5);
      expect(entitlement.canUseVoice).toBe(false);
      expect(entitlement.canUseAdvancedPersonas).toBe(false);
      expect(entitlement.canUseDeepDive).toBe(false);
      expect(entitlement.canUseFullEvaluation).toBe(false);
      expect(entitlement.canUseFullRoadmap).toBe(false);
      expect(entitlement.canUseAdvancedAnalytics).toBe(false);
      expect(entitlement.canExportPdf).toBe(false);
      expect(entitlement.maxResumeScans).toBe(1);
    });

    it('correctly tracks remaining interviews when 1 has been used', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-1',
        userId: 'user-free-1',
        periodKey: 'free_2026-09',
        interviewsUsed: 1,
        resumeScansUsed: 0,
        voiceSecondsUsed: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-free-1');
      expect(entitlement.interviewsUsed).toBe(1);
      expect(entitlement.interviewsRemaining).toBe(1);
    });

    it('reports 0 interviews remaining when 2 have been used (quota exhausted)', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-1',
        userId: 'user-free-1',
        periodKey: 'free_2026-09',
        interviewsUsed: 2,
        resumeScansUsed: 0,
        voiceSecondsUsed: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-free-1');
      expect(entitlement.interviewsRemaining).toBe(0);
    });

    it('reports 0 resume scans remaining when 1 scan has been used', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-1',
        userId: 'user-free-1',
        periodKey: 'free_2026-09',
        interviewsUsed: 0,
        resumeScansUsed: 1,
        voiceSecondsUsed: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-free-1');
      expect(entitlement.resumeScansRemaining).toBe(0);
    });
  });

  describe('PRO Tier Entitlements', () => {
    it('resolves PRO tier limits when user has active premium entitlement', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(true);
      repo.findActiveSubscriptionForUser.mockResolvedValue({
        id: 'sub-active-1',
        userId: 'user-pro-1',
        planId: 'plan-pro',
        provider: 'RAZORPAY',
        providerSubscriptionId: 'sub_rzp_123',
        status: 'ACTIVE',
        currentPeriodStart: new Date('2026-09-15T00:00:00Z'),
        currentPeriodEnd: new Date('2026-10-15T00:00:00Z'),
        startedAt: new Date('2026-09-15T00:00:00Z'),
        cancelledAt: null,
        endedAt: null,
        autoRenew: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        plan: {
          id: 'plan-pro',
          code: 'PRO_MONTHLY',
          name: 'Pro Monthly',
          description: '',
          priceInPaise: 29900,
          currency: 'INR',
          tier: 'PRO',
          billingInterval: 'MONTHLY',
          razorpayPlanId: 'plan_123',
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      } as any);

      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-2',
        userId: 'user-pro-1',
        periodKey: 'sub_sub-active-1_2026-09-15',
        interviewsUsed: 5,
        resumeScansUsed: 2,
        voiceSecondsUsed: 120,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-pro-1');

      expect(entitlement.tier).toBe('PRO');
      expect(entitlement.isPremium).toBe(true);
      expect(entitlement.interviewsLimit).toBe(30);
      expect(entitlement.interviewsUsed).toBe(5);
      expect(entitlement.interviewsRemaining).toBe(25);
      expect(entitlement.maxQuestionsPerSession).toBe(12);
      expect(entitlement.canUseVoice).toBe(true);
      expect(entitlement.canUseAdvancedPersonas).toBe(true);
      expect(entitlement.canUseDeepDive).toBe(true);
      expect(entitlement.canUseFullEvaluation).toBe(true);
      expect(entitlement.canUseFullRoadmap).toBe(true);
      expect(entitlement.canUseAdvancedAnalytics).toBe(true);
      expect(entitlement.canExportPdf).toBe(true);
      expect(entitlement.maxResumeScans).toBe(5);
      expect(entitlement.resumeScansUsed).toBe(2);
      expect(entitlement.resumeScansRemaining).toBe(3);
      expect(entitlement.periodKey).toBe('sub_sub-active-1_2026-09-15');
    });

    it('reports 0 interviews remaining when 30 have been used for Pro user', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(true);
      repo.findActiveSubscriptionForUser.mockResolvedValue({
        id: 'sub-active-1',
        currentPeriodStart: new Date('2026-09-15T00:00:00Z'),
      } as any);

      repo.findUsageQuota.mockResolvedValue({
        id: 'quota-2',
        userId: 'user-pro-1',
        periodKey: 'sub_sub-active-1_2026-09-15',
        interviewsUsed: 30,
        resumeScansUsed: 5,
        voiceSecondsUsed: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const entitlement = await entitlementService.getUserEntitlement('user-pro-1');
      expect(entitlement.interviewsRemaining).toBe(0);
      expect(entitlement.resumeScansRemaining).toBe(0);
    });
  });

  describe('Quota Consumption Operations', () => {
    it('consumes interview quota with correct period key', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue(null);
      repo.incrementInterviewUsage.mockResolvedValue({} as any);

      await entitlementService.consumeInterviewQuota('user-test-1');
      expect(repo.incrementInterviewUsage).toHaveBeenCalledWith('user-test-1', expect.stringContaining('free_'));
    });

    it('consumes resume scan quota with correct period key', async () => {
      repo.hasActivePremiumEntitlement.mockResolvedValue(false);
      repo.findActiveSubscriptionForUser.mockResolvedValue(null);
      repo.findUsageQuota.mockResolvedValue(null);
      repo.incrementResumeScanUsage.mockResolvedValue({} as any);

      await entitlementService.consumeResumeScanQuota('user-test-1');
      expect(repo.incrementResumeScanUsage).toHaveBeenCalledWith('user-test-1', expect.stringContaining('free_'));
    });
  });
});
