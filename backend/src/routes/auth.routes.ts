import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth.middleware';

const router = Router();

// ── Rate Limiters ─────────────────────────────────────────────────────────────

/** General auth limiter — registration, login, token refresh */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again after 15 minutes',
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many authentication attempts, please try again after 15 minutes',
    },
  },
});

/** Stricter limiter for OTP verification — 10 attempts per 15 minutes per IP */
const verifyOtpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many verification attempts, please try again later',
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many verification attempts, please try again later',
    },
  },
});

/** Resend OTP — 5 requests per hour per IP */
const resendOtpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many resend requests, please try again after an hour',
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many resend requests, please try again after an hour',
    },
  },
});

/** Password reset flow — same tight limit as OTP verification */
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many password reset attempts, please try again later',
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many password reset attempts, please try again later',
    },
  },
});

// ── Public Auth Routes ────────────────────────────────────────────────────────
router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.post('/refresh', authLimiter, authController.refresh);

// ── Password Reset Flow (OTP) ─────────────────────────────────────────────────
router.post('/forgot-password', passwordResetLimiter, authController.forgotPassword);
router.post('/verify-reset-otp', verifyOtpLimiter, authController.verifyResetOtp);
router.post('/reset-password', passwordResetLimiter, authController.resetPassword);


// ── Protected Auth Routes ─────────────────────────────────────────────────────
router.get('/me', authMiddleware, authController.getCurrentUser);
router.post('/logout', authMiddleware, authController.logout);
router.post('/logout-all', authMiddleware, authController.logoutAll);

export default router;
