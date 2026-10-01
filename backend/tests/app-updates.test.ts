import { requireAdmin } from '../src/middleware/admin.middleware';
import { adminAppUpdatesService } from '../src/services/admin/admin.app-updates.service';
import { prisma } from '../src/config/database';
import { ForbiddenError, UnauthorizedError, BadRequestError } from '../src/errors/AppError';
import { createAppUpdateSchema } from '../src/validators/app-update.validator';
import { compareSemver, isValidSemver } from '../src/utils/semver';
import { AppPlatform, AppUpdateStatus } from '@prisma/client';

describe('App Update Management — Backend & Security Test Suite', () => {
  let adminUserId: string;
  let normalUserId: string;
  const createdUpdateIds: string[] = [];

  beforeAll(async () => {
    // 1. Setup Admin user
    const adminUser = await prisma.user.upsert({
      where: { email: 'admin_updates_test@mockinterview.com' },
      create: {
        email: 'admin_updates_test@mockinterview.com',
        passwordHash: 'dummy_hash',
        isVerified: true,
        isActive: true,
        role: 'ADMIN',
        isAdmin: true,
      },
      update: {
        role: 'ADMIN',
        isAdmin: true,
      },
    });
    adminUserId = adminUser.id;

    // 2. Setup Normal user
    const normalUser = await prisma.user.upsert({
      where: { email: 'normal_updates_test@mockinterview.com' },
      create: {
        email: 'normal_updates_test@mockinterview.com',
        passwordHash: 'dummy_hash',
        isVerified: true,
        isActive: true,
        role: 'USER',
        isAdmin: false,
      },
      update: {
        role: 'USER',
        isAdmin: false,
      },
    });
    normalUserId = normalUser.id;
  });

  afterAll(async () => {
    // Cleanup created updates and test users
    if (createdUpdateIds.length > 0) {
      await prisma.appUpdate.deleteMany({
        where: { id: { in: createdUpdateIds } },
      });
    }
    await prisma.auditLog.deleteMany({
      where: { adminId: adminUserId },
    });
    await prisma.user.deleteMany({
      where: {
        email: {
          in: ['admin_updates_test@mockinterview.com', 'normal_updates_test@mockinterview.com'],
        },
      },
    });
    await prisma.$disconnect();
  });

  describe('Semver Comparison & Validation Utility', () => {
    it('should validate valid and invalid semantic version formats', () => {
      expect(isValidSemver('1.0.0')).toBe(true);
      expect(isValidSemver('1.4.10')).toBe(true);
      expect(isValidSemver('v2.0.0')).toBe(true);
      expect(isValidSemver('1.0.0-beta.1')).toBe(true);
      expect(isValidSemver('invalid')).toBe(false);
      expect(isValidSemver('1.0')).toBe(false);
      expect(isValidSemver('')).toBe(false);
    });

    it('should correctly compare numerical semantic versions (1.4.10 > 1.4.9)', () => {
      expect(compareSemver('1.4.10', '1.4.9')).toBe(1);
      expect(compareSemver('1.4.9', '1.4.10')).toBe(-1);
      expect(compareSemver('1.5.0', '1.4.10')).toBe(1);
      expect(compareSemver('2.0.0', '1.5.0')).toBe(1);
      expect(compareSemver('1.5.0', '1.5.0')).toBe(0);
    });
  });

  describe('Admin Authorization Middleware Protection', () => {
    it('should reject unauthenticated requests with UnauthorizedError (401)', () => {
      const req: any = { user: undefined };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      const err = next.mock.calls[0][0];
      expect(err).toBeInstanceOf(UnauthorizedError);
      expect(err.statusCode).toBe(401);
    });

    it('should reject non-admin users with ForbiddenError (403)', () => {
      const req: any = {
        user: { id: normalUserId, email: 'normal_updates_test@mockinterview.com', role: 'USER', isAdmin: false },
      };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      const err = next.mock.calls[0][0];
      expect(err).toBeInstanceOf(ForbiddenError);
      expect(err.statusCode).toBe(403);
    });

    it('should allow access to users with ADMIN role', () => {
      const req: any = {
        user: { id: adminUserId, email: 'admin_updates_test@mockinterview.com', role: 'ADMIN', isAdmin: true },
      };
      const res: any = {};
      const next = jest.fn();

      requireAdmin(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      expect(next).toHaveBeenCalledWith(); // called with no error
    });
  });

  describe('Admin App Updates CRUD & Workflow', () => {
    let testUpdateId: string;

    it('should reject creating an update with invalid semantic version', async () => {
      await expect(
        adminAppUpdatesService.createAppUpdate(adminUserId, {
          platform: 'ANDROID',
          latestVersion: '1.0-bad',
          minimumVersion: '1.0.0',
          title: 'Test Update',
          message: 'Test message',
          androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
        })
      ).rejects.toThrow(BadRequestError);
    });

    it('should reject creating an update where minimumVersion > latestVersion', async () => {
      await expect(
        adminAppUpdatesService.createAppUpdate(adminUserId, {
          platform: 'ANDROID',
          latestVersion: '1.4.0',
          minimumVersion: '1.5.0', // min > latest!
          title: 'Test Update',
          message: 'Test message',
          androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
        })
      ).rejects.toThrow(BadRequestError);
    });

    it('should reject Zod schema validation if store URL is missing for platform', () => {
      expect(() => {
        createAppUpdateSchema.parse({
          platform: 'ANDROID',
          latestVersion: '1.5.0',
          minimumVersion: '1.4.0',
          title: 'Test Update',
          message: 'Test message',
          // androidStoreUrl missing!
        });
      }).toThrow();
    });

    it('should successfully create a draft update and record audit log', async () => {
      const created = await adminAppUpdatesService.createAppUpdate(adminUserId, {
        platform: 'ANDROID',
        latestVersion: '1.5.0',
        minimumVersion: '1.4.0',
        forceUpdate: false,
        title: 'New Update Available',
        message: 'A new version with performance improvements is available.',
        whatsNew: ['Faster AI interviews', 'Voice stability fixes'],
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      });

      testUpdateId = created.id;
      createdUpdateIds.push(created.id);

      expect(created.id).toBeDefined();
      expect(created.status).toBe(AppUpdateStatus.DRAFT);
      expect(created.latestVersion).toBe('1.5.0');
      expect(created.whatsNew).toContain('Faster AI interviews');

      // Verify audit log
      const audit = await prisma.auditLog.findFirst({
        where: { targetId: created.id, action: 'APP_UPDATE_CREATE' },
      });
      expect(audit).toBeDefined();
      expect(audit?.adminId).toBe(adminUserId);
    });

    it('should successfully edit an existing update and record audit log', async () => {
      const updated = await adminAppUpdatesService.updateAppUpdate(adminUserId, testUpdateId, {
        title: 'Updated Title v1.5.0',
        forceUpdate: true,
      });

      expect(updated.title).toBe('Updated Title v1.5.0');
      expect(updated.forceUpdate).toBe(true);

      const audit = await prisma.auditLog.findFirst({
        where: { targetId: testUpdateId, action: 'APP_UPDATE_EDIT' },
        orderBy: { createdAt: 'desc' },
      });
      expect(audit).toBeDefined();
    });

    it('should successfully publish the update and disable conflicting active updates', async () => {
      // Create an earlier published update
      const earlierPublished = await adminAppUpdatesService.createAppUpdate(adminUserId, {
        platform: 'ANDROID',
        latestVersion: '1.4.0',
        minimumVersion: '1.3.0',
        title: 'Earlier Android Update',
        message: 'Earlier update message',
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
        publishNow: true,
      });
      createdUpdateIds.push(earlierPublished.id);

      expect(earlierPublished.status).toBe(AppUpdateStatus.PUBLISHED);

      // Now publish testUpdateId (which is platform ANDROID)
      const published = await adminAppUpdatesService.publishAppUpdate(adminUserId, testUpdateId);
      expect(published.status).toBe(AppUpdateStatus.PUBLISHED);
      expect(published.publishedAt).toBeDefined();

      // Check that the earlier update was automatically disabled
      const refreshedEarlier = await prisma.appUpdate.findUnique({
        where: { id: earlierPublished.id },
      });
      expect(refreshedEarlier?.status).toBe(AppUpdateStatus.DISABLED);

      // Verify only ONE published update exists for ANDROID
      const activeAndroidUpdates = await prisma.appUpdate.findMany({
        where: {
          platform: 'ANDROID',
          status: AppUpdateStatus.PUBLISHED,
        },
      });
      expect(activeAndroidUpdates.length).toBe(1);
      expect(activeAndroidUpdates[0].id).toBe(testUpdateId);

      // Verify publish audit log
      const publishAudit = await prisma.auditLog.findFirst({
        where: { targetId: testUpdateId, action: 'APP_UPDATE_PUBLISH' },
      });
      expect(publishAudit).toBeDefined();
    });

    it('should successfully disable the update and record audit log', async () => {
      const disabled = await adminAppUpdatesService.disableAppUpdate(adminUserId, testUpdateId);
      expect(disabled.status).toBe(AppUpdateStatus.DISABLED);

      const audit = await prisma.auditLog.findFirst({
        where: { targetId: testUpdateId, action: 'APP_UPDATE_DISABLE' },
        orderBy: { createdAt: 'desc' },
      });
      expect(audit).toBeDefined();
    });
  });

  describe('Public API GET /api/v1/app/version', () => {
    let publishedAndroidId: string;
    let publishedIosId: string;

    beforeAll(async () => {
      // Seed a clean published Android update
      const androidUpdate = await adminAppUpdatesService.createAppUpdate(adminUserId, {
        platform: 'ANDROID',
        latestVersion: '2.1.0',
        minimumVersion: '2.0.0',
        forceUpdate: false,
        title: 'Android Live Update',
        message: 'Live Android update description.',
        whatsNew: ['Feature A', 'Feature B'],
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
        publishNow: true,
      });
      publishedAndroidId = androidUpdate.id;
      createdUpdateIds.push(androidUpdate.id);

      // Seed a clean published iOS update
      const iosUpdate = await adminAppUpdatesService.createAppUpdate(adminUserId, {
        platform: 'IOS',
        latestVersion: '2.1.1',
        minimumVersion: '2.0.0',
        forceUpdate: true,
        title: 'iOS Critical Update',
        message: 'A critical update is required on iOS.',
        whatsNew: ['Critical security fix'],
        iosStoreUrl: 'https://apps.apple.com/app/ai-mock-interview/id123456789',
        publishNow: true,
      });
      publishedIosId = iosUpdate.id;
      createdUpdateIds.push(iosUpdate.id);
    });

    it('should return published Android configuration for android platform query', async () => {
      const response = await adminAppUpdatesService.getPublishedUpdateForPlatform('android');
      expect(response).not.toBeNull();
      expect(response?.platform).toBe('ANDROID');
      expect(response?.latestVersion).toBe('2.1.0');
      expect(response?.minimumVersion).toBe('2.0.0');
      expect(response?.storeUrl).toBe('https://play.google.com/store/apps/details?id=com.interviewcoach.app');
      expect(response?.forceUpdate).toBe(false);

      // Verify no sensitive admin data is leaked
      const rawObj = response as any;
      expect(rawObj.id).toBeUndefined();
      expect(rawObj.adminId).toBeUndefined();
      expect(rawObj.createdBy).toBeUndefined();
      expect(rawObj.status).toBeUndefined();
    });

    it('should return published iOS configuration for ios platform query', async () => {
      const response = await adminAppUpdatesService.getPublishedUpdateForPlatform('ios');
      expect(response).not.toBeNull();
      expect(response?.platform).toBe('IOS');
      expect(response?.latestVersion).toBe('2.1.1');
      expect(response?.storeUrl).toBe('https://apps.apple.com/app/ai-mock-interview/id123456789');
      expect(response?.forceUpdate).toBe(true);
    });

    it('should return null when the update is disabled and no other published update exists', async () => {
      // Disable the android update
      await adminAppUpdatesService.disableAppUpdate(adminUserId, publishedAndroidId);

      const response = await adminAppUpdatesService.getPublishedUpdateForPlatform('android');
      expect(response).toBeNull();
    });
  });
});
