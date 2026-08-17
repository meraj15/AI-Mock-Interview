import { createApp } from '../src/app';
import { hashPassword } from '../src/utils/password';
import { generateAccessToken, generateRefreshToken, verifyAccessToken, verifyRefreshToken } from '../src/utils/token';
import http from 'http';

describe('Auth Unit & Integration Tests', () => {
  let server: http.Server;
  let baseUrl: string;

  beforeAll((done) => {
    const app = createApp();
    server = app.listen(0, () => {
      const address = server.address();
      if (address && typeof address === 'object') {
        baseUrl = `http://localhost:${address.port}`;
      }
      done();
    });
  });

  afterAll((done) => {
    server.close(done);
  });

  describe('Password & Token Security Utils', () => {
    it('should hash and verify passwords with Argon2', async () => {
      const pwd = 'TestStrongPassword123';
      const hash = await hashPassword(pwd);
      expect(hash).toBeDefined();
      expect(hash).not.toEqual(pwd);

      const isValid = await import('../src/utils/password').then((m) => m.verifyPassword(pwd, hash));
      expect(isValid).toBe(true);

      const isInvalid = await import('../src/utils/password').then((m) => m.verifyPassword('WrongPassword', hash));
      expect(isInvalid).toBe(false);
    });

    it('should generate and verify valid JWT access tokens', () => {
      const userId = 'usr_test_123';
      const token = generateAccessToken(userId);
      expect(token).toBeDefined();

      const decoded = verifyAccessToken(token);
      expect(decoded.sub).toBe(userId);
      expect(decoded.type).toBe('access');
    });

    it('should generate and verify valid JWT refresh tokens', () => {
      const userId = 'usr_test_123';
      const { token, expiresAt } = generateRefreshToken(userId);
      expect(token).toBeDefined();
      expect(expiresAt).toBeInstanceOf(Date);

      const decoded = verifyRefreshToken(token);
      expect(decoded.sub).toBe(userId);
      expect(decoded.type).toBe('refresh');
    });
  });

  describe('Input Validation & Error Responses', () => {
    it('should reject registration with invalid email', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'not-an-email',
          password: 'Password123',
        }),
      });

      expect(res.status).toBe(422);
      const data = (await res.json()) as any;
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('VALIDATION_ERROR');
    });

    it('should reject registration with weak password (< 8 chars)', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'valid@example.com',
          password: 'short',
        }),
      });

      expect(res.status).toBe(422);
      const data = (await res.json()) as any;
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('VALIDATION_ERROR');
    });

    it('should reject protected /me endpoint without Authorization header', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/me`);
      expect(res.status).toBe(401);
      const data = (await res.json()) as any;
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('UNAUTHORIZED');
    });

    it('should reject protected /me endpoint with invalid Bearer token', async () => {
      const res = await fetch(`${baseUrl}/api/v1/auth/me`, {
        headers: { Authorization: 'Bearer invalid_token_value' },
      });
      expect(res.status).toBe(401);
      const data = (await res.json()) as any;
      expect(data.success).toBe(false);
      expect(data.error.code).toBe('UNAUTHORIZED');
    });
  });
});
