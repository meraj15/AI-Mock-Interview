import { AuthService } from '../src/services/auth.service';
import { hashPassword, hashToken } from '../src/utils/password';
import { hashOtp } from '../src/utils/otp';
import { AppError, UnauthorizedError, ConflictError } from '../src/errors/AppError';

// Mock dependencies
jest.mock('../src/services/email.service', () => ({
  sendPasswordResetOtpEmail: jest.fn().mockResolvedValue(undefined),
  sendOtpEmail: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../src/config/database', () => ({
  prisma: {
    userProfile: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'prof-123',
        userId: 'user-123',
        fullName: 'Test Candidate',
        skills: [],
        targetRole: null,
      }),
    },
  },
}));

jest.mock('../src/repositories/profile.repository', () => ({
  profileRepository: {
    getProfileByUserId: jest.fn().mockResolvedValue({
      id: 'prof-123',
      userId: 'user-123',
      fullName: 'Test Candidate',
      targetRole: 'Software Engineer',
      skills: ['TypeScript', 'React'],
    }),
  },
}));

describe('AuthService - Instant Registration & Forgot Password OTP', () => {
  let mockRepo: any;
  let authService: AuthService;

  beforeEach(() => {
    mockRepo = {
      findUserByEmail: jest.fn(),
      findUserById: jest.fn(),
      createUserWithProfile: jest.fn().mockResolvedValue({
        user: {
          id: 'user-new',
          email: 'newuser@example.com',
          isVerified: true,
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
          lastLoginAt: null,
        },
        profile: {
          id: 'prof-new',
          userId: 'user-new',
          fullName: 'New User',
          targetRole: 'Developer',
          skills: ['Dart', 'Flutter'],
        },
      }),
      updateLastLogin: jest.fn().mockResolvedValue({}),
      saveRefreshToken: jest.fn().mockResolvedValue({}),
      upsertPasswordResetOtp: jest.fn().mockResolvedValue({}),
      findLatestPasswordResetOtp: jest.fn(),
      incrementPasswordResetOtpAttempts: jest.fn().mockResolvedValue({}),
      consumePasswordResetOtp: jest.fn().mockResolvedValue({}),
      createPasswordResetToken: jest.fn().mockResolvedValue({}),
      findPasswordResetToken: jest.fn(),
      completePasswordReset: jest.fn().mockResolvedValue({}),
    };
    authService = new AuthService(mockRepo);
  });

  describe('Registration (Instant Account Creation — No OTP)', () => {
    it('should create user + profile immediately and return auth tokens', async () => {
      mockRepo.findUserByEmail.mockResolvedValue(null);

      const result = await authService.register({
        email: 'newuser@example.com',
        password: 'Password123!',
        fullName: 'New User',
      });

      expect(mockRepo.createUserWithProfile).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'newuser@example.com',
          fullName: 'New User',
          passwordHash: expect.any(String),
        }),
      );

      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe('newuser@example.com');
    });

    it('should throw ConflictError if email is already registered', async () => {
      mockRepo.findUserByEmail.mockResolvedValue({
        id: 'existing-1',
        email: 'existing@example.com',
        isVerified: true,
      });

      await expect(
        authService.register({
          email: 'existing@example.com',
          password: 'Password123!',
        }),
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('Login (No verification blockers)', () => {
    it('should allow login with valid credentials', async () => {
      const passwordHash = await hashPassword('Password123!');
      mockRepo.findUserByEmail.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        passwordHash,
        isActive: true,
        isVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        lastLoginAt: null,
      });

      const result = await authService.login({
        email: 'user@example.com',
        password: 'Password123!',
      });

      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe('user@example.com');
    });
  });

  describe('Forgot Password OTP Flow', () => {
    it('should return generic success when email does not exist (prevents enumeration)', async () => {
      mockRepo.findUserByEmail.mockResolvedValue(null);

      await expect(
        authService.forgotPassword({ email: 'unknown@example.com' }),
      ).resolves.toBeUndefined();

      expect(mockRepo.upsertPasswordResetOtp).not.toHaveBeenCalled();
    });

    it('should generate and store OTP in PasswordResetOtp and send email', async () => {
      mockRepo.findUserByEmail.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        isActive: true,
      });
      mockRepo.findLatestPasswordResetOtp.mockResolvedValue(null);

      await authService.forgotPassword({ email: 'user@example.com' });

      expect(mockRepo.upsertPasswordResetOtp).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          email: 'user@example.com',
          otpHash: expect.any(String),
        }),
      );
    });

    it('should reject incorrect OTP and increment attempts', async () => {
      mockRepo.findUserByEmail.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        isActive: true,
      });
      mockRepo.findLatestPasswordResetOtp.mockResolvedValue({
        id: 'otp-rec-1',
        userId: 'user-1',
        email: 'user@example.com',
        otpHash: hashOtp('123456'),
        expiresAt: new Date(Date.now() + 60000),
        attempts: 0,
        consumedAt: null,
      });

      await expect(
        authService.verifyResetOtp({
          email: 'user@example.com',
          otp: '999999', // wrong OTP
        }),
      ).rejects.toThrow(UnauthorizedError);

      expect(mockRepo.incrementPasswordResetOtpAttempts).toHaveBeenCalledWith('otp-rec-1');
      expect(mockRepo.consumePasswordResetOtp).not.toHaveBeenCalled();
    });

    it('should verify correct OTP, consume it, and return a resetToken', async () => {
      mockRepo.findUserByEmail.mockResolvedValue({
        id: 'user-1',
        email: 'user@example.com',
        isActive: true,
      });
      mockRepo.findLatestPasswordResetOtp.mockResolvedValue({
        id: 'otp-rec-1',
        userId: 'user-1',
        email: 'user@example.com',
        otpHash: hashOtp('654321'),
        expiresAt: new Date(Date.now() + 60000),
        attempts: 0,
        consumedAt: null,
      });

      const result = await authService.verifyResetOtp({
        email: 'user@example.com',
        otp: '654321',
      });

      expect(mockRepo.consumePasswordResetOtp).toHaveBeenCalledWith('otp-rec-1');
      expect(mockRepo.createPasswordResetToken).toHaveBeenCalledWith(
        'user-1',
        expect.any(String),
        expect.any(Date),
      );
      expect(result.resetToken).toBeDefined();
      expect(typeof result.resetToken).toBe('string');
    });

    it('should complete password reset using valid resetToken and invalidate sessions', async () => {
      const rawToken = 'sample_valid_reset_token_64_characters_long_1234567890abcdef';
      const tokenHash = hashToken(rawToken);

      mockRepo.findPasswordResetToken.mockResolvedValue({
        id: 'token-rec-1',
        userId: 'user-1',
        tokenHash,
        expiresAt: new Date(Date.now() + 60000),
        usedAt: null,
      });

      await authService.resetPassword({
        resetToken: rawToken,
        newPassword: 'BrandNewPassword123!',
      });

      expect(mockRepo.completePasswordReset).toHaveBeenCalledWith(
        'token-rec-1',
        'user-1',
        expect.any(String),
      );
    });
  });
});
