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
import { entitlementService, UserEntitlementContext } from './entitlement.service';

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
      code: 'PRO_MONTHLY',
      name: 'Pro Monthly',
      description: '30 AI mock interviews every month, detailed evaluations, voice practice, and analytics — billed monthly (GST-inclusive).',
      priceInPaise: 29900, // ₹299/month GST-inclusive
      billingInterval: BillingInterval.MONTHLY,
      razorpayPlanId: config.razorpay.monthlyPlanId,
      totalCount: 0, // recurring indefinitely
    },
    {
      code: 'PRO_YEARLY',
      name: 'Pro Yearly',
      description: '30 AI mock interviews every month, detailed evaluations, voice practice, and analytics — billed yearly (GST-inclusive, best value).',
      priceInPaise: 199900, // ₹1,999/year GST-inclusive
      billingInterval: BillingInterval.YEARLY,
      razorpayPlanId: config.razorpay.yearlyPlanId,
      totalCount: 0,
    },
    // Aliases for backward-compatibility
    {
      code: 'PREMIUM_MONTHLY',
      name: 'Pro Monthly',
      description: '30 AI mock interviews every month, detailed evaluations, voice practice, and analytics — billed monthly (GST-inclusive).',
      priceInPaise: 29900,
      billingInterval: BillingInterval.MONTHLY,
      razorpayPlanId: config.razorpay.monthlyPlanId,
      totalCount: 0,
    },
    {
      code: 'PREMIUM_YEARLY',
      name: 'Pro Yearly',
      description: '30 AI mock interviews every month, detailed evaluations, voice practice, and analytics — billed yearly (GST-inclusive, best value).',
      priceInPaise: 199900,
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
      let rzpPlanId = p.razorpayPlanId || undefined;

      // If Razorpay credentials are configured but plan ID was not set in env, auto-create it on Razorpay
      if (!rzpPlanId && config.razorpay.keyId && config.razorpay.keySecret) {
        try {
          const created = await razorpayService.createPlan({
            name: p.name,
            description: p.description,
            amountInPaise: p.priceInPaise,
            billingInterval: p.billingInterval,
          });
          rzpPlanId = created.planId;
          logger.info(`[RAZORPAY] Automatically created plan '${p.code}' on Razorpay: ${rzpPlanId}`);
        } catch (err: any) {
          logger.warn(`[RAZORPAY] Could not auto-create plan '${p.code}' on Razorpay: ${err?.message || err}`);
        }
      }

      await subscriptionRepository.upsertPlan({
        code: p.code,
        name: p.name,
        description: p.description,
        priceInPaise: p.priceInPaise,
        billingInterval: p.billingInterval,
        razorpayPlanId: rzpPlanId,
        isActive: true,
      });

      if (!rzpPlanId) {
        logger.warn(
          `[RAZORPAY] Plan ${p.code} seeded without Razorpay Plan ID (set RAZORPAY_${p.billingInterval}_PLAN_ID or configure RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET).`
        );
      }
    }
    logger.info('[RAZORPAY] Plan catalogue synced.');
  },

  /**
   * Return active plans (for the subscription/premium screen).
   * Prices and plan codes come from the DB — not hardcoded in Flutter.
   */
  async getActivePlans(): Promise<Plan[]> {
    const plans = await subscriptionRepository.listActivePlans();
    const proPlans = plans.filter((p) => p.code.startsWith('PRO_'));
    if (proPlans.length >= 2) {
      return proPlans;
    }
    return plans.filter((p) => !p.code.startsWith('PREMIUM_') || proPlans.length === 0);
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
  ): Promise<{
    subscription: Subscription;
    razorpaySubscriptionId: string;
    razorpayOrderId?: string;
    razorpayKeyId: string;
  }> {
    // 1. Resolve and validate plan from DB (with alias support)
    let plan = await subscriptionRepository.findPlanByCode(planCode);
    if (!plan) {
      if (planCode === 'PRO_MONTHLY') plan = await subscriptionRepository.findPlanByCode('PREMIUM_MONTHLY');
      else if (planCode === 'PRO_YEARLY') plan = await subscriptionRepository.findPlanByCode('PREMIUM_YEARLY');
      else if (planCode === 'PREMIUM_MONTHLY') plan = await subscriptionRepository.findPlanByCode('PRO_MONTHLY');
      else if (planCode === 'PREMIUM_YEARLY') plan = await subscriptionRepository.findPlanByCode('PRO_YEARLY');
    }
    if (!plan) {
      throw new NotFoundError(`Plan '${planCode}' not found`);
    }
    if (!plan.isActive) {
      throw new ValidationError(`Plan '${planCode}' is not currently available`);
    }

    // Auto-create plan on demand if Razorpay API keys are configured but plan ID was missing
    if (!plan.razorpayPlanId && config.razorpay.keyId && config.razorpay.keySecret) {
      try {
        const created = await razorpayService.createPlan({
          name: plan.name,
          description: plan.description,
          amountInPaise: plan.priceInPaise,
          billingInterval: plan.billingInterval,
        });
        await subscriptionRepository.upsertPlan({
          code: plan.code,
          name: plan.name,
          description: plan.description,
          priceInPaise: plan.priceInPaise,
          billingInterval: plan.billingInterval,
          razorpayPlanId: created.planId,
          isActive: true,
        });
        plan.razorpayPlanId = created.planId;
        logger.info(`[RAZORPAY] On-demand created Razorpay plan for '${plan.code}': ${created.planId}`);
      } catch (err: any) {
        logger.warn(`[RAZORPAY] Failed to auto-create plan '${plan.code}' on demand: ${err?.message || err}`);
      }
    }

    if (!plan.razorpayPlanId && (!config.razorpay.keyId || !config.razorpay.keySecret)) {
      throw new AppError(
        `Plan '${planCode}' has no Razorpay Plan ID configured`,
        503,
        'PAYMENT_UNAVAILABLE'
      );
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

    // 3. Create payment session (via Subscriptions if configured on Razorpay, or direct Order)
    let providerId: string;
    let isOrder = false;

    if (plan.razorpayPlanId) {
      try {
        const rzpResult = await razorpayService.createSubscription({
          planId: plan.razorpayPlanId,
          totalCount: 0, // recurring indefinitely
        });
        providerId = rzpResult.subscriptionId;
      } catch (err: any) {
        logger.warn(`[RAZORPAY] Subscriptions API failed (${err?.message || err}). Creating standard Razorpay order.`);
        const rzpOrder = await razorpayService.createOrder({
          amountInPaise: plan.priceInPaise,
          receipt: `sub_${userId.slice(0, 8)}_${Date.now()}`,
          notes: { userId, planCode, planId: plan.id },
        });
        providerId = rzpOrder.orderId;
        isOrder = true;
      }
    } else {
      if (!config.razorpay.keyId || !config.razorpay.keySecret) {
        throw new AppError(
          `Plan '${planCode}' has no Razorpay Plan ID configured`,
          503,
          'PAYMENT_UNAVAILABLE'
        );
      }
      const rzpOrder = await razorpayService.createOrder({
        amountInPaise: plan.priceInPaise,
        receipt: `sub_${userId.slice(0, 8)}_${Date.now()}`,
        notes: { userId, planCode, planId: plan.id },
      });
      providerId = rzpOrder.orderId;
      isOrder = true;
    }

    // 4. Persist to DB
    const subscription = await subscriptionRepository.createSubscription({
      userId,
      planId: plan.id,
      providerSubscriptionId: providerId,
      status: SubscriptionStatus.CREATED,
    });

    logger.info(`[RAZORPAY] { "operation": "create_subscription", "userId": "${userId}", "plan": "${planCode}", "providerId": "${providerId}", "isOrder": ${isOrder}, "success": true }`);

    return {
      subscription,
      razorpaySubscriptionId: providerId,
      razorpayOrderId: isOrder ? providerId : undefined,
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

    // 1. Verify HMAC signature (supports both Subscriptions and Orders)
    const isOrderPayment = razorpaySubscriptionId.startsWith('order_');
    const signatureValid = isOrderPayment
      ? razorpayService.verifyOrderSignature({
          orderId: razorpaySubscriptionId,
          paymentId: razorpayPaymentId,
          signature: razorpaySignature,
        })
      : razorpayService.verifySubscriptionSignature({
          subscriptionId: razorpaySubscriptionId,
          paymentId: razorpayPaymentId,
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
      const now = new Date();
      const periodEnd = new Date(now);
      if (subscription.plan?.billingInterval === BillingInterval.YEARLY) {
        periodEnd.setFullYear(periodEnd.getFullYear() + 1);
      } else {
        periodEnd.setMonth(periodEnd.getMonth() + 1);
      }

      await subscriptionRepository.updateSubscription(subscription.id, {
        status: SubscriptionStatus.ACTIVE,
        startedAt: rzpPayment.capturedAt ?? now,
        currentPeriodStart: now,
        currentPeriodEnd: periodEnd,
      });

      // 7. Activate entitlement
      await subscriptionRepository.upsertEntitlement({
        userId,
        status: EntitlementStatus.ACTIVE,
        expiresAt: periodEnd,
      });

      logger.info(`[RAZORPAY] { "operation": "verify_payment", "userId": "${userId}", "paymentId": "${razorpayPaymentId}", "status": "ACTIVE", "plan": "${subscription.plan?.code}", "success": true }`);
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
    entitlement: UserEntitlementContext;
  }> {
    const subscription = await subscriptionRepository.findLatestSubscriptionForUser(userId);
    const isPremium = await subscriptionRepository.hasActivePremiumEntitlement(userId);
    const entitlement = await entitlementService.getUserEntitlement(userId);

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
        entitlement,
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
      entitlement,
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

    if (subscription.cancelledAt !== null || !subscription.autoRenew) {
      throw new ConflictError('Subscription is already scheduled for cancellation');
    }

    // Cancel with Razorpay (safely guarded against non-recurring IDs and upstream errors)
    try {
      await razorpayService.cancelSubscription(
        subscription.providerSubscriptionId,
        cancelAtCycleEnd
      );
    } catch (err: any) {
      logger.warn(
        `[RAZORPAY] Razorpay cancel failed for ${subscription.providerSubscriptionId} (${err?.error?.description || err?.message || err}). Proceeding with internal cancellation.`
      );
    }

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
