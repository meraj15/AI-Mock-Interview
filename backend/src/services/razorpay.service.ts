/**
 * razorpay.service.ts
 *
 * Thin wrapper around the official Razorpay Node.js SDK.
 * All Razorpay API calls are centralised here so the rest of the codebase
 * interacts with our internal models, not raw Razorpay objects.
 *
 * SECURITY: RAZORPAY_KEY_SECRET stays in this file and config only.
 * It must never be returned to Flutter or logged.
 */
import Razorpay from 'razorpay';
import crypto from 'crypto';
import { config } from '../config';
import { logger } from '../utils/logger';

// ── Razorpay client — lazy singleton ──────────────────────────────────────────
// The client is NOT created at module load time.
// This allows the server to start cleanly even without Razorpay credentials
// (e.g. in development without a Razorpay account).
// The client is constructed on the first actual payment operation.

let _razorpayClient: Razorpay | null = null;

function getRazorpayClient(): Razorpay {
  if (_razorpayClient) return _razorpayClient;

  if (!config.razorpay.keyId || !config.razorpay.keySecret) {
    throw new Error(
      'Razorpay credentials (RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET) are not configured. ' +
      'Add them to your .env file to enable payment features.'
    );
  }

  _razorpayClient = new Razorpay({
    key_id: config.razorpay.keyId,
    key_secret: config.razorpay.keySecret,
  });

  logger.info('[RAZORPAY] Client initialised.');
  return _razorpayClient;
}


// ── Types ──────────────────────────────────────────────────────────────────────

export interface RazorpaySubscriptionCreateInput {
  planId: string;       // Razorpay plan_id from Dashboard
  totalCount: number;   // Number of billing cycles (use 0 for infinite)
  quantity?: number;
  notifyCustomer?: boolean;
}

export interface RazorpaySubscriptionResult {
  subscriptionId: string;  // Razorpay sub_xxx
  status: string;
  shortUrl?: string;
}

export interface RazorpayPaymentResult {
  paymentId: string;
  amount: number;
  currency: string;
  status: string;
  subscriptionId?: string;
  capturedAt?: Date;
}

// ── Service ────────────────────────────────────────────────────────────────────

export const razorpayService = {
  /**
   * Create a plan in Razorpay programmatically.
   * Enables automated plan generation when API keys are configured.
   */
  async createPlan(params: {
    name: string;
    description: string;
    amountInPaise: number;
    billingInterval: string;
  }): Promise<{ planId: string }> {
    const payload = {
      period: params.billingInterval.toLowerCase() === 'yearly' ? 'yearly' : 'monthly',
      interval: 1,
      item: {
        name: params.name,
        amount: params.amountInPaise,
        currency: 'INR',
        description: params.description,
      },
    };

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const plan = await (getRazorpayClient().plans.create as any)(payload);
    return { planId: plan.id as string };
  },

  /**
   * Create a Razorpay subscription for the given plan.
   * This does NOT trigger payment — it returns a subscription_id
   * that Flutter uses to open the checkout.
   */
  async createSubscription(
    input: RazorpaySubscriptionCreateInput
  ): Promise<RazorpaySubscriptionResult> {
    const payload = {
      plan_id: input.planId,
      total_count: input.totalCount,
      quantity: input.quantity ?? 1,
      customer_notify: input.notifyCustomer === false ? 0 : 1,
    };

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sub = await (getRazorpayClient().subscriptions.create as any)(payload);

    return {
      subscriptionId: sub.id as string,
      status: sub.status as string,
      shortUrl: sub.short_url as string | undefined,
    };
  },

  /**
   * Cancel a Razorpay subscription.
   * cancelAtCycleEnd = true  cancel at end of current billing cycle
   * cancelAtCycleEnd = false  cancel immediately
   */
  async cancelSubscription(
    providerSubscriptionId: string,
    cancelAtCycleEnd = true
  ): Promise<void> {
    await getRazorpayClient().subscriptions.cancel(
      providerSubscriptionId,
      cancelAtCycleEnd
    );
  },

  /**
   * Fetch a payment by its Razorpay payment_id.
   * Used to verify payment details server-side after Flutter callback.
   */
  async fetchPayment(paymentId: string): Promise<RazorpayPaymentResult> {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const payment = await (getRazorpayClient().payments.fetch as any)(paymentId) as any;
    return {
      paymentId: payment.id as string,
      amount: payment.amount as number,
      currency: payment.currency as string,
      status: payment.status as string,
      subscriptionId: payment.subscription_id as string | undefined,
      capturedAt: payment.captured_at
        ? new Date((payment.captured_at as number) * 1000)
        : undefined,
    };
  },

  /**
   * Create a standard Razorpay order.
   * Works immediately on all Razorpay accounts for direct plan checkout.
   */
  async createOrder(params: {
    amountInPaise: number;
    receipt: string;
    notes?: Record<string, string>;
  }): Promise<{ orderId: string; amount: number; currency: string }> {
    const payload = {
      amount: params.amountInPaise,
      currency: 'INR',
      receipt: params.receipt,
      notes: params.notes ?? {},
    };

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const order = await (getRazorpayClient().orders.create as any)(payload);
    return {
      orderId: order.id as string,
      amount: order.amount as number,
      currency: order.currency as string,
    };
  },

  /**
   * Verify HMAC-SHA256 signature for standard orders:
   *   razorpay_order_id + "|" + razorpay_payment_id
   */
  verifyOrderSignature(params: {
    orderId: string;
    paymentId: string;
    signature: string;
  }): boolean {
    const { orderId, paymentId, signature } = params;
    const message = `${orderId}|${paymentId}`;
    const expected = crypto
      .createHmac('sha256', config.razorpay.keySecret)
      .update(message)
      .digest('hex');
    return expected === signature;
  },

  /**
   * Verify the HMAC-SHA256 signature Razorpay attaches to subscription payments.
   *
   * For subscriptions the signed string is:
   *   razorpay_payment_id + "|" + razorpay_subscription_id
   *
   * Returns true only when the signature matches.
   */
  verifySubscriptionSignature(params: {
    paymentId: string;
    subscriptionId: string;
    signature: string;
  }): boolean {
    const { paymentId, subscriptionId, signature } = params;
    const message = `${paymentId}|${subscriptionId}`;
    const expected = crypto
      .createHmac('sha256', config.razorpay.keySecret)
      .update(message)
      .digest('hex');
    return expected === signature;
  },

  /**
   * Verify a Razorpay webhook signature.
   * Uses the Razorpay SDK static method which wraps the same HMAC-SHA256 logic.
   * rawBody must be the raw Buffer/string NOT the parsed JSON object.
   */
  verifyWebhookSignature(rawBody: string, signature: string): boolean {
    if (!config.razorpay.webhookSecret) {
      logger.error('[RAZORPAY] Webhook secret not configured rejecting webhook');
      return false;
    }
    try {
      return Razorpay.validateWebhookSignature(
        rawBody,
        signature,
        config.razorpay.webhookSecret
      );
    } catch {
      return false;
    }
  },

  /**
   * Return the public key_id so Flutter can initialise Razorpay Checkout.
   * This value is non-sensitive (it is the publishable key, not the secret).
   */
  getPublicKeyId(): string {
    return config.razorpay.keyId;
  },
};
