/**
 * subscription.routes.ts
 *
 * All subscription API routes require JWT authentication.
 * Route prefix: /api/v1/subscriptions (registered in app.ts)
 */
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.middleware';
import { subscriptionController } from '../controllers/subscription.controller';

const router = Router();

// All subscription routes require a valid JWT
router.use(authMiddleware);

// GET /api/v1/subscriptions/plans — list available plans
router.get('/plans', subscriptionController.getPlans);

// GET /api/v1/subscriptions/me — current user's subscription status
router.get('/me', subscriptionController.getMySubscription);

// POST /api/v1/subscriptions/create — create a Razorpay subscription
router.post('/create', subscriptionController.createSubscription);

// POST /api/v1/subscriptions/verify-payment — verify after Flutter checkout
router.post('/verify-payment', subscriptionController.verifyPayment);

// POST /api/v1/subscriptions/me/cancel — cancel current user's active subscription
// (Flutter-friendly: no subscription ID needed in the URL — must be before /:id/cancel)
router.post('/me/cancel', subscriptionController.cancelMySubscription);

// POST /api/v1/subscriptions/:id/cancel — cancel a specific subscription by ID
router.post('/:id/cancel', subscriptionController.cancelSubscription);

export default router;
