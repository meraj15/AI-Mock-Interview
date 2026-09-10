import crypto from 'crypto';
import { hashToken } from './password';

/** 10 minutes in milliseconds */
export const OTP_EXPIRY_MS = 10 * 60 * 1000;

/** Maximum failed verification attempts before OTP is locked */
export const OTP_MAX_ATTEMPTS = 5;

/** Minimum seconds between resend requests (60 seconds) */
export const OTP_RESEND_COOLDOWN_MS = 60 * 1000;

/**
 * Generate a cryptographically secure 6-digit OTP.
 * Leading zeros are preserved via padStart.
 * NEVER log or return this value from an API response.
 */
export function generateOtp(): string {
  // crypto.randomInt(0, 1_000_000) gives a uniform integer in [0, 999999]
  return String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
}

/**
 * Hash an OTP using SHA-256 for safe storage.
 * Reuses the existing hashToken utility.
 */
export function hashOtp(otp: string): string {
  return hashToken(otp);
}

/**
 * Returns the expiry Date object for a freshly generated OTP.
 */
export function otpExpiresAt(): Date {
  return new Date(Date.now() + OTP_EXPIRY_MS);
}
