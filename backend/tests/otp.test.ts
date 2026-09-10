import { generateOtp, hashOtp, otpExpiresAt, OTP_EXPIRY_MS, OTP_MAX_ATTEMPTS, OTP_RESEND_COOLDOWN_MS } from '../src/utils/otp';
import { verifyResetOtpSchema, forgotPasswordSchema } from '../src/validators/auth.validator';

describe('OTP Utility', () => {
  describe('generateOtp', () => {
    it('should generate a 6-digit numeric string', () => {
      for (let i = 0; i < 50; i++) {
        const otp = generateOtp();
        expect(otp).toHaveLength(6);
        expect(/^\d{6}$/.test(otp)).toBe(true);
      }
    });

    it('should be cryptographically diverse', () => {
      const set = new Set<string>();
      for (let i = 0; i < 20; i++) {
        set.add(generateOtp());
      }
      expect(set.size).toBeGreaterThan(15);
    });
  });

  describe('hashOtp', () => {
    it('should deterministically produce a 64-character SHA-256 hex string', () => {
      const hash1 = hashOtp('123456');
      const hash2 = hashOtp('123456');
      expect(hash1).toBe(hash2);
      expect(hash1).toHaveLength(64);
      expect(/^[0-9a-f]{64}$/.test(hash1)).toBe(true);
    });

    it('should produce different hashes for different OTPs', () => {
      expect(hashOtp('123456')).not.toBe(hashOtp('654321'));
    });
  });

  describe('otpExpiresAt', () => {
    it('should return a timestamp ~10 minutes in the future', () => {
      const before = Date.now();
      const expiresAt = otpExpiresAt();
      const after = Date.now();

      expect(expiresAt.getTime()).toBeGreaterThanOrEqual(before + OTP_EXPIRY_MS);
      expect(expiresAt.getTime()).toBeLessThanOrEqual(after + OTP_EXPIRY_MS + 100);
    });
  });

  describe('Constants', () => {
    it('should have production security constants configured', () => {
      expect(OTP_EXPIRY_MS).toBe(10 * 60 * 1000); // 10 mins
      expect(OTP_MAX_ATTEMPTS).toBe(5);
      expect(OTP_RESEND_COOLDOWN_MS).toBe(60 * 1000); // 60 secs
    });
  });
});

describe('OTP Validators for Password Reset', () => {
  describe('verifyResetOtpSchema', () => {
    it('should accept valid email and 6-digit otp', () => {
      const result = verifyResetOtpSchema.safeParse({
        email: 'user@example.com',
        otp: '123456',
      });
      expect(result.success).toBe(true);
    });

    it('should reject non-6-digit otp', () => {
      expect(verifyResetOtpSchema.safeParse({ email: 'user@example.com', otp: '12345' }).success).toBe(false);
      expect(verifyResetOtpSchema.safeParse({ email: 'user@example.com', otp: '1234567' }).success).toBe(false);
      expect(verifyResetOtpSchema.safeParse({ email: 'user@example.com', otp: 'abcdef' }).success).toBe(false);
    });

    it('should reject invalid email', () => {
      expect(verifyResetOtpSchema.safeParse({ email: 'invalid-email', otp: '123456' }).success).toBe(false);
    });
  });

  describe('forgotPasswordSchema', () => {
    it('should accept valid email', () => {
      expect(forgotPasswordSchema.safeParse({ email: 'user@example.com' }).success).toBe(true);
    });

    it('should reject invalid email', () => {
      expect(forgotPasswordSchema.safeParse({ email: 'not-an-email' }).success).toBe(false);
    });
  });
});
