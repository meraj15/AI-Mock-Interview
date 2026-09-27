/**
 * webhook.routes.ts
 *
 * Razorpay webhook endpoint.
 * Route prefix: /api/v1/webhooks (registered in app.ts)
 *
 * CRITICAL: The webhook route uses express.raw() to capture the raw body
 * buffer required for HMAC signature verification.
 * It must NOT use express.json() middleware — the body must remain raw.
 */
import { Router, Request, Response } from 'express';
import { webhookController } from '../controllers/webhook.controller';

const router = Router();

/**
 * Custom middleware to capture the raw body buffer alongside
 * the standard express.raw() parsing, so the controller can
 * access both the raw bytes and the Buffer.
 */
router.post(
  '/razorpay',
  // Use express.raw to keep the body unparsed for HMAC verification.
  // The type must be 'application/json' because Razorpay sends JSON.
  (req: Request & { rawBody?: Buffer }, _res: Response, next: () => void) => {
    let data = Buffer.alloc(0);
    req.on('data', (chunk: Buffer) => {
      data = Buffer.concat([data, chunk]);
    });
    req.on('end', () => {
      req.rawBody = data;
      next();
    });
  },
  webhookController.handleRazorpay
);

export default router;
