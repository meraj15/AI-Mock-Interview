/**
 * subscription.service.ts
 *
 * Core business logic for the subscription/payment system.
 * Orchestrates between the database (subscriptionRepository),
 * the Razorpay SDK wrapper (razorpayService), and the entitlement model.
 *
 * Rules enforced here:
 *  - Only the backend resolves Razorpay Plan IDs (never from Flutter)
 *  - Duplicate subscription prevention (concurrent-safe via DB check)
 *  - Server-side payment verification before activating entitlement
 *  - Webhook idempotency via WebhookEvent table
 *  - Entitlement is always derived from subscription state, never from Flutter
 */
import { config } from '../config';
import { logger } from '../utils/logger';
import {
  subscriptionRepository,
  SubscriptionStatus,
  EntitlementStatus,
  TransactionStatus,
  BillingInterval,
} from '../repositories/subscription.repository';
import { razorpayService } from './razorpay.service';
import {
  ConflictError,
  NotFoundError,
  ValidationError,
  ForbiddenError,
  AppError,
} from '../errors/AppError';
import { Plan, Subscription } from '@prisma/client';

// ── Plan catalogue ─────────────────────────────────────────────────────────────
// Prices are in paise (INR). 1 INR = 100 paise.
// Razorpay Plan IDs come from the backend env only.

interface PlanSeedConfig {
  code: string;
  name: string;
  description: string;
  priceInPaise: number;
  billingInterval: BillingInterval;
  razorpayPlanId: string;
  totalCount: number; // billing cycles; 0 = forever
}

function buildPlanCatalogue(): PlanSeedConfig[] {
  return [
    {
      code: 'PREMIUM_MONTHLY',
      name: 'Premium Monthly',
      description: 'Unlimited AI mock interviews, detailed evaluations, and analytics — billed monthly.',
      priceInPaise: 19900, // ₹199/month — update via env if pricing changes
      billingInterval: BillingInterval.MONTHLY,
      razorpayPlanId: config.razorpay.monthlyPlanId,
      totalCount: 0, // recurring indefinitely
    },
    {
      code: 'PREMIUM_YEARLY',
      name: 'Premium Yearly',
      description: 'Unlimited AI mock interviews, detailed evaluations, and analytics — billed yearly (best value).',
      priceInPaise: 199900, // ₹1999/year — update via env if pricing changes
      billingInterval: BillingInterval.YEARLY,
      razorpayPlanId: config.razorpay.yearlyPlanId,
      totalCount: 0,
    },
  ];
}

// ── Razorpay status → internal status mapping ──────────────────────────────────

function mapRazorpayStatusToInternal(rzpStatus: string): SubscriptionStatus {
  switch (rzpStatus.toLowerCase()) {
    case 'created':     return SubscriptionStatus.CREATED;
    case 'authenticated': return SubscriptionStatus.AUTHENTICATED;
    case 'active':      return SubscriptionStatus.ACTIVE;
    case 'pending':     return SubscriptionStatus.PAYMENT_PENDING;
    case 'halted':      return SubscriptionStatus.HALTED;
    case 'cancelled':   return SubscriptionStatus.CANCELLED;
    case 'completed':   return SubscriptionStatus.COMPLETED;
    case 'expired':     return SubscriptionStatus.EXPIRED;
    default:
      logger.warn(`[RAZORPAY] Unknown subscription status received: ${rzpStatus}`);
      return SubscriptionStatus.CREATED;
  }
}

// ── Entitlement derivation ─────────────────────────────────────────────────────

/**
 * Derive the correct entitlement state from a subscription status.
 * Business rule:
 *   ACTIVE  → entitlement ACTIVE (until currentPeriodEnd)
 *   AUTHENTICATED → entitlement INACTIVE (payment not yet confirmed)
 *   PAYMENT_PENDING → entitlement GRACE (give short window)
 *   HALTED / CANCELLED / COMPLETED / EXPIRED → INACTIVE
 */
function deriveEntitlementStatus(
  status: SubscriptionStatus,
  currentPeriodEnd?: Date | null
): { status: EntitlementStatus; expiresAt: Date | null } {
  switch (status) {
    case SubscriptionStatus.ACTIVE:
      return {
        status: EntitlementStatus.ACTIVE,
        expiresAt: currentPeriodEnd ?? null,
      };
    case SubscriptionStatus.PAYMENT_PENDING:
      // Grace: keep access until end of current period
      return {
        status: EntitlementStatus.GRACE,
        expiresAt: currentPeriodEnd ?? null,
      };
    case SubscriptionStatus.AUTHENTICATED:
    case SubscriptionStatus.CREATED:
    case SubscriptionStatus.HALTED:
    case SubscriptionStatus.CANCELLED:
    case SubscriptionStatus.COMPLETED:
    case SubscriptionStatus.EXPIRED:
    default:
      return { status: EntitlementStatus.INACTIVE, expiresAt: null };
  }
}

// ── Service ────────────────────────────────────────────────────────────────────

export const subscriptionService = {
  /**
   * Seed / sync the plan catalogue into the database.
   * Called on app start. Uses upsert so existing data is preserved.
   */
  async syncPlans(): Promise<void> {
    const plans = buildPlanCatalogue();
    for (const p of plans) {
      if (!p.razorpayPlanId) {
        logger.warn(`[RAZORPAY] Plan ${p.code} has no Razorpay Plan ID configured — skipping.`);
        continue;
      }
      await subscriptionRepository.upsertPlan({
        code: p.code,
        name: p.name,
        description: p.description,
        priceInPaise: p.priceInPaise,
        billingInterval: p.billingInterval,
        razorpayPlanId: p.razorpayPlanId,
        isActive: true,
      });
    }
    logger.info('[RAZORPAY] Plan catalogue synced.');
  },

  /**
   * Return active plans (for the subscription/premium screen).
   * Prices and plan codes come from the DB — not hardcoded in Flutter.
   */
  async getActivePlans(): Promise<Plan[]> {
    return subscriptionRepository.listActivePlans();
  },

  /**
   * Create a Razorpay subscription and record it in the DB.
   *
   * Security rules enforced:
   *  - Plan code validated against DB (not from Flutter)
   *  - Razorpay Plan ID resolved from DB/env (never from Flutter)
   *  - Duplicate check before creating
   *  - Idempotency: if an active subscription already exists, return it
   */
  async createSubscription(
    userId: string,
    planCode: string
  ): Promise<{ subscription: Subscription; razorpaySubscriptionId: string; razorpayKeyId: string }> {
    // 1. Resolve and validate plan from DB
    const plan = await subscriptionRepository.findPlanByCode(planCode);
    if (!plan) {
      throw new NotFoundError(`Plan '${planCode}' not found`);
    }
    if (!plan.isActive) {
      throw new ValidationError(`Plan '${planCode}' is not currently available`);
    }
    if (!plan.razorpayPlanId) {
      throw new AppError(`Plan '${planCode}' has no Razorpay Plan ID configured`, 503, 'PAYMENT_UNAVAILABLE');
    }

    // 2. Check for existing active subscription (idempotency / duplicate prevention)
    const existing = await subscriptionRepository.findActiveSubscriptionForUser(userId);
    if (existing) {
      if (existing.providerSubscriptionId) {
        logger.info(`[RAZORPAY] { "operation": "create_subscription", "userId": "${userId}", "plan": "${planCode}", "note": "returning_existing" }`);
        return {
          subscription: existing,
          razorpaySubscriptionId: existing.providerSubscriptionId,
          razorpayKeyId: razorpayService.getPublicKeyId(),
        };
      }
      throw new ConflictError('You already have an active subscription');
    }

    // 3. Create Razorpay subscription using the plan's Razorpay Plan ID
    const rzpResult = await razorpayService.createSubscription({
      planId: plan.razorpayPlanId,
      totalCount: 0, // recurring indefinitely
    });

    // 4. Persist to DB
    const subscription = await subscriptionRepository.createSubscription({
      userId,
      planId: plan.id,
      providerSubscriptionId: rzpResult.subscriptionId,
      status: SubscriptionStatus.CREATED,
    });

    logger.info(`[RAZORPAY] { "operation": "create_subscription", "userId": "${userId}", "plan": "${planCode}", "subscriptionId": "${rzpResult.subscriptionId}", "success": true }`);

    return {
      subscription,
      razorpaySubscriptionId: rzpResult.subscriptionId,
      razorpayKeyId: razorpayService.getPublicKeyId(),
    };
  },

  /**
   * Verify a payment after Flutter checkout success callback.
   *
   * Security rules:
   *  - Verify HMAC signature before trusting any data
   *  - Fetch payment details from Razorpay (not from Flutter)
   *  - Confirm payment belongs to the expected subscription
   *  - Update subscription + entitlement only after verification
   */
  async verifyPayment(params: {
    userId: string;
    razorpayPaymentId: string;
    razorpaySubscriptionId: string;
    razorpaySignature: string;
  }): Promise<{ isPremium: boolean }> {
    const { userId, razorpayPaymentId, razorpaySubscriptionId, razorpaySignature } = params;

    // 1. Verify HMAC signature
    const signatureValid = razorpayService.verifySubscriptionSignature({
      paymentId: razorpayPaymentId,
      subscriptionId: razorpaySubscriptionId,
      signature: razorpaySignature,
    });

    if (!signatureValid) {
      logger.warn(`[RAZORPAY] { "operation": "verify_payment", "userId": "${userId}", "error": "invalid_signature" }`);
      throw new ForbiddenError('Payment signature verification failed', 'PAYMENT_SIGNATURE_INVALID');
    }

    // 2. Find our subscription record
    const subscription = await subscriptionRepository.findSubscriptionByProviderId(razorpaySubscriptionId);
    if (!subscription) {
      throw new NotFoundError('Subscription record not found');
    }

    // 3. Confirm ownership
    if (subscription.userId !== userId) {
      logger.warn(`[RAZORPAY] { "operation": "verify_payment", "userId": "${userId}", "error": "ownership_mismatch" }`);
      throw new ForbiddenError('Subscription does not belong to this user', 'FORBIDDEN');
    }

    // 4. Fetch payment details from Razorpay (server-side — do not trust Flutter)
    let rzpPayment;
    try {
      rzpPayment = await razorpayService.fetchPayment(razorpayPaymentId);
    } catch (err) {
      logger.error(`[RAZORPAY] { "operation": "fetch_payment", "paymentId": "${razorpayPaymentId}", "error": "razorpay_api_failure" }`);
      throw new AppError('Unable to verify payment with payment provider. Please try again.', 502, 'PAYMENT_PROVIDER_ERROR');
    }

    // 5. Record the transaction (idempotent — skip if already recorded)
    const existingTx = await subscriptionRepository.findPaymentTransactionByProviderId(razorpayPaymentId);
    if (!existingTx) {
      await subscriptionRepository.createPaymentTransaction({
        userId,
        subscriptionId: subscription.id,
        providerPaymentId: razorpayPaymentId,
        amount: rzpPayment.amount,
        currency: rzpPayment.currency,
        status: rzpPayment.status === 'captured' ? TransactionStatus.CAPTURED : TransactionStatus.PENDING,
        paidAt: rzpPayment.capturedAt,
      });
    }

    // 6. Update subscription status if payment is captured
    if (rzpPayment.status === 'captured') {
      await subscriptionRepository.updateSubscription(subscription.id, {
        status: SubscriptionStatus.ACTIVE,
        startedAt: rzpPayment.capturedAt ?? new Date(),
      });

      // 7. Activate entitlement
      await subscriptionRepository.upsertEntitlement({
        userId,
        status: EntitlementStatus.ACTIVE,
        expiresAt: subscription.currentPeriodEnd,
      });

      logger.info(`[RAZORPAY] { "operation": "verify_payment", "userId": "${userId}", "paymentId": "${razorpayPaymentId}", "success": true }`);
      return { isPremium: true };
    }

    // Payment exists but not yet captured (e.g. authorised but pending)
    logger.info(`[RAZORPAY] { "operation": "verify_payment", "userId": "${userId}", "paymentStatus": "${rzpPayment.status}", "note": "not_captured_yet" }`);
    return { isPremium: false };
  },

  /**
   * Get the current subscription status for a user.
   * This is what Flutter calls on app start / profile load.
   */
  async getMySubscription(userId: string): Promise<{
    subscriptionId: string | null;
    plan: string | null;
    status: SubscriptionStatus | null;
    isPremium: boolean;
    currentPeriodStart: Date | null;
    currentPeriodEnd: Date | null;
    autoRenew: boolean;
    cancelledAt: Date | null;
  }> {
    const subscription = await subscriptionRepository.findLatestSubscriptionForUser(userId);
    const isPremium = await subscriptionRepository.hasActivePremiumEntitlement(userId);

    if (!subscription) {
      return {
        subscriptionId: null,
        plan: 'FREE',
        status: null,
        isPremium: false,
        currentPeriodStart: null,
        currentPeriodEnd: null,
        autoRenew: false,
        cancelledAt: null,
      };
    }

    return {
      subscriptionId: subscription.id,
      plan: subscription.plan.code,
      status: subscription.status,
      isPremium,
      currentPeriodStart: subscription.currentPeriodStart,
      currentPeriodEnd: subscription.currentPeriodEnd,
      autoRenew: subscription.autoRenew,
      cancelledAt: subscription.cancelledAt,
    };
  },

  /**
   * Cancel the current user's active subscription by userId.
   * Flutter calls this without knowing the internal subscription ID.
   * The backend resolves the active subscription from the user's record.
   */
  async cancelMySubscription(
    userId: string,
    cancelAtCycleEnd = true
  ): Promise<void> {
    const subscription = await subscriptionRepository.findActiveSubscriptionForUser(userId);
    if (!subscription) {
      throw new NotFoundError('No active subscription found to cancel');
    }
    await this.cancelSubscription(userId, subscription.id, cancelAtCycleEnd);
  },

  /**
   * Cancel a user's subscription.
   * Default: cancel at end of current billing cycle.
   *
   * Security: Subscription ownership verified here before calling Razorpay.
   */
  async cancelSubscription(
    userId: string,
    subscriptionId: string,
    cancelAtCycleEnd = true
  ): Promise<void> {
    const subscription = await subscriptionRepository.findSubscriptionById(subscriptionId);

    if (!subscription) {
      throw new NotFoundError('Subscription not found');
    }

    if (subscription.userId !== userId) {
      throw new ForbiddenError('You are not authorised to cancel this subscription', 'FORBIDDEN');
    }

    if (!subscription.providerSubscriptionId) {
      throw new ValidationError('No Razorpay subscription ID on record');
    }

    const cancellableStatuses: SubscriptionStatus[] = [
      SubscriptionStatus.ACTIVE,
      SubscriptionStatus.AUTHENTICATED,
      SubscriptionStatus.PAYMENT_PENDING,
    ];
    if (!cancellableStatuses.includes(subscription.status)) {
      throw new ConflictError(`Subscription is already ${subscription.status.toLowerCase()} and cannot be cancelled`);
    }

    // Cancel with Razorpay
    await razorpayService.cancelSubscription(
      subscription.providerSubscriptionId,
      cancelAtCycleEnd
    );

    const now = new Date();
    await subscriptionRepository.updateSubscription(subscriptionId, {
      status: cancelAtCycleEnd ? subscription.status : SubscriptionStatus.CANCELLED,
      cancelledAt: now,
      autoRenew: false,
    });

    // If immediate cancellation, deactivate entitlement
    if (!cancelAtCycleEnd) {
      await subscriptionRepository.upsertEntitlement({
        userId,
        status: EntitlementStatus.INACTIVE,
        expiresAt: null,
      });
    }

    logger.info(`[RAZORPAY] { "operation": "cancel_subscription", "userId": "${userId}", "subscriptionId": "${subscriptionId}", "atCycleEnd": ${cancelAtCycleEnd}, "success": true }`);
  },

  // ── Webhook Processing ─────────────────────────────────────────────────────

  /**
   * Process a verified Razorpay webhook event.
   * This function is ONLY called after the HMAC signature has been verified.
   *
   * Idempotency: each event is deduplicated by Razorpay event ID.
   * Safe to call multiple times with the same event.
   */
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async processWebhookEvent(event: any): Promise<void> {
    const eventType: string = event.event;
    const eventId: string = event.id ?? `${eventType}_${Date.now()}`;

    // 1. Idempotency — bail if already processed
    const existing = await subscriptionRepository.findWebhookEvent(eventId);
    if (existing) {
      logger.info(`[RAZORPAY] { "operation": "webhook", "event": "${eventType}", "eventId": "${eventId}", "note": "duplicate_skipped" }`);
      return;
    }

    // 2. Persist the event record (marks it as processed)
    await subscriptionRepository.createWebhookEvent({
      eventId,
      eventType,
      payload: event,
    });

    const subscriptionEntity = event.payload?.subscription?.entity;
    const paymentEntity = event.payload?.payment?.entity;

    logger.info(`[RAZORPAY] { "operation": "webhook", "event": "${eventType}", "eventId": "${eventId}", "success": true }`);

    // 3. Route to handler
    switch (eventType) {
      case 'subscription.authenticated':
        await this._handleSubscriptionAuthenticated(subscriptionEntity);
        break;
      case 'subscription.activated':
      case 'subscription.charged':
        await this._handleSubscriptionActivated(subscriptionEntity, paymentEntity);
        break;
      case 'subscription.pending':
        await this._handleSubscriptionPending(subscriptionEntity);
        break;
      case 'subscription.halted':
        await this._handleSubscriptionHalted(subscriptionEntity);
        break;
      case 'subscription.cancelled':
        await this._handleSubscriptionCancelled(subscriptionEntity);
        break;
      case 'subscription.completed':
        await this._handleSubscriptionCompleted(subscriptionEntity);
        break;
      default:
        logger.info(`[RAZORPAY] Unhandled webhook event: ${eventType}`);
    }
  },

  // ── Private webhook handlers ───────────────────────────────────────────────

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionAuthenticated(subscriptionEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;
    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.AUTHENTICATED,
    });
  },

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionActivated(subscriptionEntity: any, paymentEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;

    const currentPeriodStart = subscriptionEntity.current_start
      ? new Date(subscriptionEntity.current_start * 1000)
      : new Date();
    const currentPeriodEnd = subscriptionEntity.current_end
      ? new Date(subscriptionEntity.current_end * 1000)
      : null;

    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.ACTIVE,
      startedAt: sub.startedAt ?? currentPeriodStart,
      currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? undefined,
    });

    // Record payment transaction if present and not already recorded
    if (paymentEntity?.id) {
      const existingTx = await subscriptionRepository.findPaymentTransactionByProviderId(paymentEntity.id);
      if (!existingTx) {
        await subscriptionRepository.createPaymentTransaction({
          userId: sub.userId,
          subscriptionId: sub.id,
          providerPaymentId: paymentEntity.id,
          amount: paymentEntity.amount ?? 0,
          currency: paymentEntity.currency ?? 'INR',
          status: paymentEntity.status === 'captured' ? TransactionStatus.CAPTURED : TransactionStatus.PENDING,
          paidAt: paymentEntity.captured_at ? new Date(paymentEntity.captured_at * 1000) : undefined,
        });
      }
    }

    // Activate entitlement
    await subscriptionRepository.upsertEntitlement({
      userId: sub.userId,
      status: EntitlementStatus.ACTIVE,
      expiresAt: currentPeriodEnd,
    });
  },

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionPending(subscriptionEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;

    const currentPeriodEnd = subscriptionEntity.current_end
      ? new Date(subscriptionEntity.current_end * 1000)
      : null;

    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.PAYMENT_PENDING,
    });

    // Grace: keep access until end of current period
    await subscriptionRepository.upsertEntitlement({
      userId: sub.userId,
      status: EntitlementStatus.GRACE,
      expiresAt: currentPeriodEnd,
    });
  },

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionHalted(subscriptionEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;
    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.HALTED,
    });
    await subscriptionRepository.upsertEntitlement({
      userId: sub.userId,
      status: EntitlementStatus.INACTIVE,
      expiresAt: null,
    });
  },

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionCancelled(subscriptionEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;

    const cancelledAt = subscriptionEntity.ended_at
      ? new Date(subscriptionEntity.ended_at * 1000)
      : new Date();

    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.CANCELLED,
      cancelledAt,
      autoRenew: false,
    });
    await subscriptionRepository.upsertEntitlement({
      userId: sub.userId,
      status: EntitlementStatus.INACTIVE,
      expiresAt: null,
    });
  },

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async _handleSubscriptionCompleted(subscriptionEntity: any): Promise<void> {
    if (!subscriptionEntity?.id) return;
    const sub = await subscriptionRepository.findSubscriptionByProviderId(subscriptionEntity.id);
    if (!sub) return;

    const endedAt = subscriptionEntity.ended_at
      ? new Date(subscriptionEntity.ended_at * 1000)
      : new Date();

    await subscriptionRepository.updateSubscription(sub.id, {
      status: SubscriptionStatus.COMPLETED,
      endedAt,
    });
    await subscriptionRepository.upsertEntitlement({
      userId: sub.userId,
      status: EntitlementStatus.INACTIVE,
      expiresAt: null,
    });
  },
};
