/**
 * subscription.repository.ts
 *
 * All database operations for the subscription/payment system.
 * Follows the same patterns as interview.repository.ts.
 */
import { prisma } from '../config/database';
import {
  Plan,
  Subscription,
  PaymentTransaction,
  Entitlement,
  WebhookEvent,
  SubscriptionStatus,
  EntitlementStatus,
  TransactionStatus,
  BillingInterval,
  PaymentProvider,
} from '@prisma/client';

// ── Re-export Prisma enums for use throughout the service layer ────────────────

export {
  SubscriptionStatus,
  EntitlementStatus,
  TransactionStatus,
  BillingInterval,
  PaymentProvider,
};

// ── Types ──────────────────────────────────────────────────────────────────────

export interface CreateSubscriptionInput {
  userId: string;
  planId: string;
  provider?: PaymentProvider;
  providerSubscriptionId?: string;
  status?: SubscriptionStatus;
}

export interface UpdateSubscriptionInput {
  status?: SubscriptionStatus;
  providerSubscriptionId?: string;
  currentPeriodStart?: Date;
  currentPeriodEnd?: Date;
  startedAt?: Date;
  cancelledAt?: Date;
  endedAt?: Date;
  autoRenew?: boolean;
}

export interface CreatePaymentTransactionInput {
  userId: string;
  subscriptionId?: string;
  provider?: PaymentProvider;
  providerPaymentId?: string;
  providerOrderId?: string;
  amount: number;
  currency?: string;
  status?: TransactionStatus;
  paidAt?: Date;
}

export interface UpsertEntitlementInput {
  userId: string;
  feature?: string;
  status: EntitlementStatus;
  expiresAt?: Date | null;
}

export type SubscriptionWithPlan = Subscription & { plan: Plan };

// ── Repository ─────────────────────────────────────────────────────────────────

export const subscriptionRepository = {
  // ── Plans ──────────────────────────────────────────────────────────────────

  async findPlanByCode(code: string): Promise<Plan | null> {
    return prisma.plan.findUnique({ where: { code } });
  },

  async listActivePlans(): Promise<Plan[]> {
    return prisma.plan.findMany({ where: { isActive: true }, orderBy: { priceInPaise: 'asc' } });
  },

  /**
   * Upsert a plan from seeding/config.
   * If the plan already exists, update razorpayPlanId / price only.
   */
  async upsertPlan(data: {
    code: string;
    name: string;
    description?: string;
    priceInPaise: number;
    currency?: string;
    billingInterval: BillingInterval;
    razorpayPlanId?: string;
    isActive?: boolean;
  }): Promise<Plan> {
    return prisma.plan.upsert({
      where: { code: data.code },
      create: {
        code: data.code,
        name: data.name,
        description: data.description ?? '',
        priceInPaise: data.priceInPaise,
        currency: data.currency ?? 'INR',
        billingInterval: data.billingInterval,
        razorpayPlanId: data.razorpayPlanId,
        isActive: data.isActive ?? true,
      },
      update: {
        name: data.name,
        description: data.description,
        priceInPaise: data.priceInPaise,
        razorpayPlanId: data.razorpayPlanId,
        isActive: data.isActive ?? true,
      },
    });
  },

  // ── Subscriptions ──────────────────────────────────────────────────────────

  async createSubscription(input: CreateSubscriptionInput): Promise<Subscription> {
    return prisma.subscription.create({
      data: {
        userId: input.userId,
        planId: input.planId,
        provider: input.provider ?? PaymentProvider.RAZORPAY,
        providerSubscriptionId: input.providerSubscriptionId,
        status: input.status ?? SubscriptionStatus.CREATED,
      },
    });
  },

  async findSubscriptionById(id: string): Promise<SubscriptionWithPlan | null> {
    return prisma.subscription.findUnique({
      where: { id },
      include: { plan: true },
    });
  },

  async findSubscriptionByProviderId(
    providerSubscriptionId: string
  ): Promise<SubscriptionWithPlan | null> {
    return prisma.subscription.findUnique({
      where: { providerSubscriptionId },
      include: { plan: true },
    });
  },

  /**
   * Find the most recent active/pending subscription for a user.
   * Used for duplicate-subscription prevention.
   */
  async findActiveSubscriptionForUser(userId: string): Promise<SubscriptionWithPlan | null> {
    return prisma.subscription.findFirst({
      where: {
        userId,
        status: {
          in: [
            SubscriptionStatus.CREATED,
            SubscriptionStatus.AUTHENTICATED,
            SubscriptionStatus.ACTIVE,
            SubscriptionStatus.PAYMENT_PENDING,
          ],
        },
      },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });
  },

  async findLatestSubscriptionForUser(userId: string): Promise<SubscriptionWithPlan | null> {
    return prisma.subscription.findFirst({
      where: { userId },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });
  },

  async updateSubscription(
    id: string,
    input: UpdateSubscriptionInput
  ): Promise<Subscription> {
    return prisma.subscription.update({
      where: { id },
      data: input,
    });
  },

  // ── Payment Transactions ───────────────────────────────────────────────────

  async createPaymentTransaction(
    input: CreatePaymentTransactionInput
  ): Promise<PaymentTransaction> {
    return prisma.paymentTransaction.create({
      data: {
        userId: input.userId,
        subscriptionId: input.subscriptionId,
        provider: input.provider ?? PaymentProvider.RAZORPAY,
        providerPaymentId: input.providerPaymentId,
        providerOrderId: input.providerOrderId,
        amount: input.amount,
        currency: input.currency ?? 'INR',
        status: input.status ?? TransactionStatus.PENDING,
        paidAt: input.paidAt,
      },
    });
  },

  async findPaymentTransactionByProviderId(
    providerPaymentId: string
  ): Promise<PaymentTransaction | null> {
    return prisma.paymentTransaction.findUnique({
      where: { providerPaymentId },
    });
  },

  async updatePaymentTransactionStatus(
    providerPaymentId: string,
    status: TransactionStatus,
    paidAt?: Date
  ): Promise<PaymentTransaction> {
    return prisma.paymentTransaction.update({
      where: { providerPaymentId },
      data: { status, paidAt },
    });
  },

  // ── Entitlements ───────────────────────────────────────────────────────────

  /**
   * Upsert the PREMIUM entitlement for a user.
   * This is the single authoritative check Flutter should call.
   */
  async upsertEntitlement(input: UpsertEntitlementInput): Promise<Entitlement> {
    const feature = input.feature ?? 'PREMIUM';
    return prisma.entitlement.upsert({
      where: { userId_feature: { userId: input.userId, feature } },
      create: {
        userId: input.userId,
        feature,
        status: input.status,
        expiresAt: input.expiresAt,
      },
      update: {
        status: input.status,
        expiresAt: input.expiresAt,
      },
    });
  },

  async findEntitlement(userId: string, feature = 'PREMIUM'): Promise<Entitlement | null> {
    return prisma.entitlement.findUnique({
      where: { userId_feature: { userId, feature } },
    });
  },

  /**
   * Central entitlement check — the ONLY place in the codebase that answers
   * "Does this user have active Premium access?"
   */
  async hasActivePremiumEntitlement(userId: string): Promise<boolean> {
    const entitlement = await prisma.entitlement.findUnique({
      where: { userId_feature: { userId, feature: 'PREMIUM' } },
    });

    if (!entitlement) return false;

    if (entitlement.status === EntitlementStatus.ACTIVE) {
      // Check expiry if set
      if (entitlement.expiresAt && entitlement.expiresAt < new Date()) {
        return false;
      }
      return true;
    }

    if (entitlement.status === EntitlementStatus.GRACE) {
      if (entitlement.expiresAt && entitlement.expiresAt > new Date()) {
        return true;
      }
    }

    return false;
  },

  // ── Webhook Events (idempotency) ───────────────────────────────────────────

  /**
   * Check if we have already processed this webhook event.
   * Razorpay may deliver the same event more than once.
   */
  async findWebhookEvent(eventId: string): Promise<WebhookEvent | null> {
    return prisma.webhookEvent.findUnique({ where: { eventId } });
  },

  async createWebhookEvent(data: {
    provider?: PaymentProvider;
    eventId: string;
    eventType: string;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    payload: any;
  }): Promise<WebhookEvent> {
    return prisma.webhookEvent.create({
      data: {
        provider: data.provider ?? PaymentProvider.RAZORPAY,
        eventId: data.eventId,
        eventType: data.eventType,
        payload: data.payload,
      },
    });
  },
};
