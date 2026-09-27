/**
 * webhook.controller.ts
 *
 * Razorpay webhook endpoint handler.
 *
 * CRITICAL SECURITY RULES enforced here:
 *  1. Raw body (Buffer) is used for HMAC signature verification
 *     before any business logic runs.
 *  2. Every event is logged with type and ID — without sensitive payment data.
 *  3. The webhook secret is NEVER logged.
 *  4. The endpoint always returns 200 quickly to prevent Razorpay retries
 *     from timing out. Heavy processing happens after the 200 response is sent.
 *  5. Idempotency is enforced in subscriptionService.processWebhookEvent().
 */
import { Request, Response } from 'express';
import { razorpayService } from '../services/razorpay.service';
import { subscriptionService } from '../services/subscription.service';
import { logger } from '../utils/logger';

export const webhookController = {
  /**
   * POST /api/v1/webhooks/razorpay
   *
   * This route must use express.raw({ type: 'application/json' })
   * so the raw body buffer is available for HMAC verification.
   * Do NOT parse with express.json() before this handler.
   */
  async handleRazorpay(req: Request, res: Response): Promise<void> {
    const signature = req.headers['x-razorpay-signature'] as string | undefined;

    if (!signature) {
      logger.warn('[RAZORPAY] { "operation": "webhook", "error": "missing_signature" }');
      res.status(400).json({ success: false, message: 'Missing webhook signature' });
      return;
    }

    // Raw body is provided by express.raw() middleware on this route.
    const rawBody = (req as Request & { rawBody?: Buffer }).rawBody;
    const bodyString = rawBody
      ? rawBody.toString('utf-8')
      : typeof req.body === 'string'
        ? req.body
        : JSON.stringify(req.body);

    // ── Verify HMAC signature before processing ────────────────────────────
    const isValid = razorpayService.verifyWebhookSignature(bodyString, signature);

    if (!isValid) {
      logger.warn('[RAZORPAY] { "operation": "webhook", "error": "invalid_signature" }');
      res.status(400).json({ success: false, message: 'Invalid webhook signature' });
      return;
    }

    // ── Parse payload ──────────────────────────────────────────────────────
    let event: Record<string, unknown>;
    try {
      event = JSON.parse(bodyString) as Record<string, unknown>;
    } catch {
      logger.warn('[RAZORPAY] { "operation": "webhook", "error": "invalid_json" }');
      res.status(400).json({ success: false, message: 'Invalid JSON payload' });
      return;
    }

    const eventType = event.event as string;
    const eventId = event.id as string;
    logger.info(`[RAZORPAY] { "operation": "webhook_received", "event": "${eventType}", "eventId": "${eventId}" }`);

    // ── Acknowledge immediately to prevent Razorpay timeout retries ────────
    res.status(200).json({ success: true, received: true });

    // ── Process asynchronously (after 200 sent) ────────────────────────────
    setImmediate(async () => {
      try {
        await subscriptionService.processWebhookEvent(event);
      } catch (err) {
        // Errors here don't affect the HTTP response (already sent 200).
        // Razorpay will retry on non-200, but we use idempotency table
        // to handle duplicate deliveries safely.
        logger.error(`[RAZORPAY] { "operation": "webhook_processing", "event": "${eventType}", "error": "${(err as Error).message}" }`);
      }
    });
  },
};
