/**
 * entitlement.service.ts
 *
 * Single source of truth for all subscription entitlements and usage quotas.
 * Enforces business rules across interview start, evaluation, resume parsing,
 * analytics, and PDF reports.
 */
import {
  subscriptionRepository,
  SubscriptionStatus,
} from '../repositories/subscription.repository';
import { logger } from '../utils/logger';

export type PlanTier = 'FREE' | 'PRO';

export interface UserEntitlementContext {
  tier: PlanTier;
  isPremium: boolean;
  interviewsLimit: number;
  interviewsUsed: number;
  interviewsRemaining: number;
  maxQuestionsPerSession: number;
  canUseVoice: boolean;
  canUseAdvancedPersonas: boolean;
  canUseDeepDive: boolean;
  canUseFullEvaluation: boolean;
  canUseFullRoadmap: boolean;
  canUseAdvancedAnalytics: boolean;
  canExportPdf: boolean;
  maxResumeScans: number;
  resumeScansUsed: number;
  resumeScansRemaining: number;
  periodKey: string;
}

export const FREE_LIMITS = {
  interviewsLimit: 2,
  maxQuestionsPerSession: 5,
  maxResumeScans: 1,
  historySessionLimit: 3,
  standardPersona: 'Professional Interviewer',
} as const;

export const PRO_LIMITS = {
  interviewsLimit: 30,
  maxQuestionsPerSession: 12,
  maxResumeScans: 5,
} as const;

export class EntitlementService {
  /**
   * Resolves the current tier, entitlements, and quota usage for a user.
   */
  async getUserEntitlement(userId: string): Promise<UserEntitlementContext> {
    const isPremium = await subscriptionRepository.hasActivePremiumEntitlement(userId);
    const activeSub = await subscriptionRepository.findActiveSubscriptionForUser(userId);

    const tier: PlanTier = isPremium ? 'PRO' : 'FREE';

    // Period Key derivation:
    // Paid subscriptions use billing period (currentPeriodStart).
    // Free tier uses calendar month (YYYY-MM).
    let periodKey: string;
    if (isPremium && activeSub) {
      const startTag = activeSub.currentPeriodStart
        ? activeSub.currentPeriodStart.toISOString().slice(0, 10)
        : 'active';
      periodKey = `sub_${activeSub.id}_${startTag}`;
    } else {
      const now = new Date();
      periodKey = `free_${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
    }

    const quota = await subscriptionRepository.findUsageQuota(userId, periodKey);
    const interviewsUsed = quota?.interviewsUsed ?? 0;
    const resumeScansUsed = quota?.resumeScansUsed ?? 0;

    let context: UserEntitlementContext;

    if (tier === 'PRO') {
      const interviewsRemaining = Math.max(0, PRO_LIMITS.interviewsLimit - interviewsUsed);
      const resumeScansRemaining = Math.max(0, PRO_LIMITS.maxResumeScans - resumeScansUsed);

      context = {
        tier: 'PRO',
        isPremium: true,
        interviewsLimit: PRO_LIMITS.interviewsLimit,
        interviewsUsed,
        interviewsRemaining,
        maxQuestionsPerSession: PRO_LIMITS.maxQuestionsPerSession,
        canUseVoice: true,
        canUseAdvancedPersonas: true,
        canUseDeepDive: true,
        canUseFullEvaluation: true,
        canUseFullRoadmap: true,
        canUseAdvancedAnalytics: true,
        canExportPdf: true,
        maxResumeScans: PRO_LIMITS.maxResumeScans,
        resumeScansUsed,
        resumeScansRemaining,
        periodKey,
      };
    } else {
      const interviewsRemaining = Math.max(0, FREE_LIMITS.interviewsLimit - interviewsUsed);
      const resumeScansRemaining = Math.max(0, FREE_LIMITS.maxResumeScans - resumeScansUsed);

      context = {
        tier: 'FREE',
        isPremium: false,
        interviewsLimit: FREE_LIMITS.interviewsLimit,
        interviewsUsed,
        interviewsRemaining,
        maxQuestionsPerSession: FREE_LIMITS.maxQuestionsPerSession,
        canUseVoice: false,
        canUseAdvancedPersonas: false,
        canUseDeepDive: false,
        canUseFullEvaluation: false,
        canUseFullRoadmap: false,
        canUseAdvancedAnalytics: false,
        canExportPdf: false,
        maxResumeScans: FREE_LIMITS.maxResumeScans,
        resumeScansUsed,
        resumeScansRemaining,
        periodKey,
      };
    }

    logger.info(
      `[ENTITLEMENT] ${JSON.stringify({
        userId,
        tier: context.tier,
        interviewsRemaining: context.interviewsRemaining,
        interviewsUsed: context.interviewsUsed,
        interviewsLimit: context.interviewsLimit,
        periodKey,
      })}`
    );

    return context;
  }

  /**
   * Atomically records an interview attempt against user's quota.
   */
  async consumeInterviewQuota(userId: string): Promise<void> {
    const entitlement = await this.getUserEntitlement(userId);
    await subscriptionRepository.incrementInterviewUsage(userId, entitlement.periodKey);

    logger.info(
      `[QUOTA] ${JSON.stringify({
        userId,
        operation: 'start_interview',
        tier: entitlement.tier,
        used: entitlement.interviewsUsed + 1,
        limit: entitlement.interviewsLimit,
        periodKey: entitlement.periodKey,
      })}`
    );
  }

  /**
   * Atomically records a resume parse against user's quota.
   */
  async consumeResumeScanQuota(userId: string): Promise<void> {
    const entitlement = await this.getUserEntitlement(userId);
    await subscriptionRepository.incrementResumeScanUsage(userId, entitlement.periodKey);

    logger.info(
      `[QUOTA] ${JSON.stringify({
        userId,
        operation: 'parse_resume',
        tier: entitlement.tier,
        used: entitlement.resumeScansUsed + 1,
        limit: entitlement.maxResumeScans,
        periodKey: entitlement.periodKey,
      })}`
    );
  }
}

export const entitlementService = new EntitlementService();
