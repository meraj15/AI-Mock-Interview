/**
 * subscription.controller.ts
 *
 * HTTP handlers for the subscription API.
 * Follows the same pattern as interview.controller.ts:
 *  - Zod validation at the controller layer
 *  - All business logic in subscriptionService
 *  - Standard { success, data, message } response format
 */
import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest } from '../types/auth.types';
import { subscriptionService } from '../services/subscription.service';
import { UnauthorizedError } from '../errors/AppError';

// ── Validation Schemas ─────────────────────────────────────────────────────────

const createSubscriptionSchema = z.object({
  planCode: z
    .string()
    .min(1, 'planCode is required')
    .toUpperCase()
    .regex(/^[A-Z0-9_]+$/, 'planCode must be alphanumeric with underscores'),
});

const verifyPaymentSchema = z.object({
  razorpayPaymentId: z.string().min(1, 'razorpayPaymentId is required'),
  razorpaySubscriptionId: z.string().min(1, 'razorpaySubscriptionId is required'),
  razorpaySignature: z.string().min(1, 'razorpaySignature is required'),
});

const cancelSubscriptionSchema = z.object({
  cancelAtCycleEnd: z.boolean().optional().default(true),
});

// ── Controller ─────────────────────────────────────────────────────────────────

export const subscriptionController = {
  /**
   * GET /api/v1/subscriptions/plans
   * Returns active plans. Flutter uses this to display plan prices.
   * Prices come from DB — never hardcoded in Flutter.
   */
  async getPlans(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const plans = await subscriptionService.getActivePlans();
      res.status(200).json({
        success: true,
        message: 'Plans retrieved successfully',
        data: {
          plans: plans.map((p) => ({
            id: p.id,
            code: p.code,
            name: p.name,
            description: p.description,
            priceInPaise: p.priceInPaise,
            currency: p.currency,
            billingInterval: p.billingInterval,
          })),
        },
      });
    } catch (err) {
      next(err);
    }
  },

  /**
   * GET /api/v1/subscriptions/me
   * Returns the current user's subscription status.
   * Flutter calls this on app start / profile load.
   */
  async getMySubscription(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        next(new UnauthorizedError());
        return;
      }
      const result = await subscriptionService.getMySubscription(req.user.id);
      res.status(200).json({
        success: true,
        message: 'Subscription retrieved successfully',
        data: result,
      });
    } catch (err) {
      next(err);
    }
  },

  /**
   * POST /api/v1/subscriptions/create
   * Create a Razorpay subscription and return the checkout details.
   * Flutter uses the returned razorpaySubscriptionId + razorpayKeyId
   * to open Razorpay Checkout.
   *
   * Security: planCode is validated against DB. Razorpay Plan ID
   * is resolved entirely on the backend.
   */
  async createSubscription(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        next(new UnauthorizedError());
        return;
      }

      const body = createSubscriptionSchema.parse(req.body);

      const result = await subscriptionService.createSubscription(
        req.user.id,
        body.planCode
      );

      res.status(201).json({
        success: true,
        message: 'Subscription created. Complete payment in Razorpay Checkout.',
        data: {
          subscriptionId: result.subscription.id,
          razorpaySubscriptionId: result.razorpaySubscriptionId,
          razorpayKeyId: result.razorpayKeyId,
        },
      });
    } catch (err) {
      next(err);
    }
  },

  /**
   * POST /api/v1/subscriptions/verify-payment
   * Verifies a Razorpay payment after Flutter checkout success.
   *
   * Security:
   *  - HMAC signature verified on backend
   *  - Payment details fetched from Razorpay (not trusted from Flutter)
   *  - Subscription ownership verified
   */
  async verifyPayment(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        next(new UnauthorizedError());
        return;
      }

      const body = verifyPaymentSchema.parse(req.body);

      const result = await subscriptionService.verifyPayment({
        userId: req.user.id,
        razorpayPaymentId: body.razorpayPaymentId,
        razorpaySubscriptionId: body.razorpaySubscriptionId,
        razorpaySignature: body.razorpaySignature,
      });

      res.status(200).json({
        success: true,
        message: result.isPremium
          ? 'Payment verified. Premium is now active.'
          : 'Payment received. Your subscription is being activated.',
        data: { isPremium: result.isPremium },
      });
    } catch (err) {
      next(err);
    }
  },

  /**
   * POST /api/v1/subscriptions/me/cancel
   * Cancel the current user's active subscription.
   * Flutter does NOT need to know the internal subscription ID.
   */
  async cancelMySubscription(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        next(new UnauthorizedError());
        return;
      }
      const body = cancelSubscriptionSchema.parse(req.body);
      await subscriptionService.cancelMySubscription(
        req.user.id,
        body.cancelAtCycleEnd
      );
      res.status(200).json({
        success: true,
        message: body.cancelAtCycleEnd
          ? 'Subscription will be cancelled at the end of the current billing cycle.'
          : 'Subscription cancelled immediately.',
        data: null,
      });
    } catch (err) {
      next(err);
    }
  },

  /**
   * POST /api/v1/subscriptions/:id/cancel
   * Cancel a subscription by its ID.
   * Subscription ownership verified in the service layer.
   */
  async cancelSubscription(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      if (!req.user) {
        next(new UnauthorizedError());
        return;
      }

      const id = req.params['id'] as string;
      const body = cancelSubscriptionSchema.parse(req.body);

      await subscriptionService.cancelSubscription(
        req.user.id,
        id,
        body.cancelAtCycleEnd
      );

      res.status(200).json({
        success: true,
        message: body.cancelAtCycleEnd
          ? 'Subscription will be cancelled at the end of the current billing cycle.'
          : 'Subscription cancelled immediately.',
        data: null,
      });
    } catch (err) {
      next(err);
    }
  },
};
