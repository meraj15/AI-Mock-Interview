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

// ── Razorpay client singleton ──────────────────────────────────────────────────

function createRazorpayClient(): Razorpay {
  if (!config.razorpay.keyId || !config.razorpay.keySecret) {
    logger.warn('[RAZORPAY] API credentials not configured. Payment features disabled.');
  }
  return new Razorpay({
    key_id: config.razorpay.keyId,
    key_secret: config.razorpay.keySecret,
  });
}

const razorpayClient = createRazorpayClient();

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
    const sub = await (razorpayClient.subscriptions.create as any)(payload);

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
    await razorpayClient.subscriptions.cancel(
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
    const payment = await (razorpayClient.payments.fetch as any)(paymentId) as any;
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
