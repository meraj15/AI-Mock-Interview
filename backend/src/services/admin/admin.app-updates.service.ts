import { prisma } from '../../config/database';
import { telemetryService } from '../telemetry.service';
import { NotFoundError, BadRequestError } from '../../errors/AppError';
import { isValidSemver, compareSemver } from '../../utils/semver';
import { normalizeWhatsNew } from '../../validators/app-update.validator';
import { AppPlatform, AppUpdateStatus, AppUpdate } from '@prisma/client';

export interface CreateAppUpdateInput {
  platform: 'ANDROID' | 'IOS' | 'BOTH';
  latestVersion: string;
  minimumVersion: string;
  forceUpdate?: boolean;
  title: string;
  message: string;
  whatsNew?: string[] | string;
  androidStoreUrl?: string | null;
  iosStoreUrl?: string | null;
  releaseDate?: string | Date | null;
  publishNow?: boolean;
}

export interface UpdateAppUpdateInput {
  platform?: 'ANDROID' | 'IOS' | 'BOTH';
  latestVersion?: string;
  minimumVersion?: string;
  forceUpdate?: boolean;
  title?: string;
  message?: string;
  whatsNew?: string[] | string;
  androidStoreUrl?: string | null;
  iosStoreUrl?: string | null;
  releaseDate?: string | Date | null;
}

export interface AppUpdateListParams {
  platform?: string;
  status?: string;
  page?: number | string;
  limit?: number | string;
}

export interface PublicAppVersionResponse {
  platform: string;
  latestVersion: string;
  minimumVersion: string;
  forceUpdate: boolean;
  title: string;
  message: string;
  whatsNew: string[];
  storeUrl: string;
  releaseDate: Date | null;
}

export class AdminAppUpdatesService {
  /**
   * Helper: disables other published updates matching the platform to ensure
   * only ONE published configuration is active per platform.
   */
  private async disableConflictingPublishedUpdates(
    platform: AppPlatform,
    excludeId?: string,
    tx = prisma
  ): Promise<void> {
    let conflictingPlatforms: AppPlatform[] = [];

    if (platform === AppPlatform.BOTH) {
      // Both supersedes any active Android, iOS, or Both update
      conflictingPlatforms = [AppPlatform.BOTH, AppPlatform.ANDROID, AppPlatform.IOS];
    } else if (platform === AppPlatform.ANDROID) {
      // Android supersedes previous Android or Both updates
      conflictingPlatforms = [AppPlatform.ANDROID, AppPlatform.BOTH];
    } else if (platform === AppPlatform.IOS) {
      // iOS supersedes previous iOS or Both updates
      conflictingPlatforms = [AppPlatform.IOS, AppPlatform.BOTH];
    }

    await tx.appUpdate.updateMany({
      where: {
        status: AppUpdateStatus.PUBLISHED,
        platform: { in: conflictingPlatforms },
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
      data: {
        status: AppUpdateStatus.DISABLED,
      },
    });
  }

  /**
   * List update records with filtering and pagination for CMS.
   */
  async listAppUpdates(params: AppUpdateListParams) {
    const page = Math.max(1, Number(params.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(params.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.platform && ['ANDROID', 'IOS', 'BOTH'].includes(params.platform.toUpperCase())) {
      where.platform = params.platform.toUpperCase() as AppPlatform;
    }

    if (params.status && ['DRAFT', 'PUBLISHED', 'DISABLED'].includes(params.status.toUpperCase())) {
      where.status = params.status.toUpperCase() as AppUpdateStatus;
    }

    const [total, updates] = await Promise.all([
      prisma.appUpdate.count({ where }),
      prisma.appUpdate.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }],
        skip,
        take: limit,
      }),
    ]);

    return {
      updates,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 1,
      },
    };
  }

  /**
   * Fetch a single app update by ID.
   */
  async getAppUpdateById(id: string): Promise<AppUpdate> {
    const update = await prisma.appUpdate.findUnique({
      where: { id },
    });

    if (!update) {
      throw new NotFoundError(`App update with ID ${id} not found`);
    }

    return update;
  }

  /**
   * Create a new app update.
   */
  async createAppUpdate(adminId: string, data: CreateAppUpdateInput, ipAddress?: string): Promise<AppUpdate> {
    const normalizedWhatsNew = normalizeWhatsNew(data.whatsNew);
    const isPublishingNow = Boolean(data.publishNow);
    const platform = data.platform as AppPlatform;

    // Validate semver
    if (!isValidSemver(data.latestVersion)) {
      throw new BadRequestError(`Invalid latestVersion "${data.latestVersion}". Must be valid semver.`);
    }
    if (!isValidSemver(data.minimumVersion)) {
      throw new BadRequestError(`Invalid minimumVersion "${data.minimumVersion}". Must be valid semver.`);
    }
    if (compareSemver(data.minimumVersion, data.latestVersion) > 0) {
      throw new BadRequestError('Minimum supported version cannot be greater than latest version.');
    }

    // Validate store URLs if publishing
    if (isPublishingNow) {
      if ((platform === AppPlatform.ANDROID || platform === AppPlatform.BOTH) && !data.androidStoreUrl) {
        throw new BadRequestError('Google Play Store URL is required for Android/Both platforms.');
      }
      if ((platform === AppPlatform.IOS || platform === AppPlatform.BOTH) && !data.iosStoreUrl) {
        throw new BadRequestError('Apple App Store URL is required for iOS/Both platforms.');
      }
    }

    const created = await prisma.$transaction(async (tx) => {
      if (isPublishingNow) {
        await this.disableConflictingPublishedUpdates(platform, undefined, tx as any);
      }

      return tx.appUpdate.create({
        data: {
          platform,
          latestVersion: data.latestVersion.trim(),
          minimumVersion: data.minimumVersion.trim(),
          forceUpdate: Boolean(data.forceUpdate),
          title: data.title.trim(),
          message: data.message.trim(),
          whatsNew: normalizedWhatsNew,
          androidStoreUrl: data.androidStoreUrl?.trim() || null,
          iosStoreUrl: data.iosStoreUrl?.trim() || null,
          status: isPublishingNow ? AppUpdateStatus.PUBLISHED : AppUpdateStatus.DRAFT,
          publishedAt: isPublishingNow ? new Date() : null,
          releaseDate: data.releaseDate ? new Date(data.releaseDate) : (isPublishingNow ? new Date() : null),
          createdBy: adminId,
        },
      });
    });

    // Record audit log
    await telemetryService.recordAuditLog({
      adminId,
      action: 'APP_UPDATE_CREATE',
      targetType: 'APP_UPDATE',
      targetId: created.id,
      newValue: {
        platform: created.platform,
        latestVersion: created.latestVersion,
        minimumVersion: created.minimumVersion,
        forceUpdate: created.forceUpdate,
        status: created.status,
      },
      reason: `Created app update v${created.latestVersion} (${created.platform}) with status ${created.status}`,
      ipAddress,
    });

    if (isPublishingNow) {
      await telemetryService.recordAuditLog({
        adminId,
        action: 'APP_UPDATE_PUBLISH',
        targetType: 'APP_UPDATE',
        targetId: created.id,
        newValue: { status: AppUpdateStatus.PUBLISHED, publishedAt: created.publishedAt },
        reason: `Published app update v${created.latestVersion} directly on creation`,
        ipAddress,
      });
    }

    return created;
  }

  /**
   * Edit draft/existing app update.
   */
  async updateAppUpdate(
    adminId: string,
    id: string,
    data: UpdateAppUpdateInput,
    ipAddress?: string
  ): Promise<AppUpdate> {
    const existing = await this.getAppUpdateById(id);

    const platform = (data.platform as AppPlatform) ?? existing.platform;
    const latestVersion = data.latestVersion?.trim() ?? existing.latestVersion;
    const minimumVersion = data.minimumVersion?.trim() ?? existing.minimumVersion;

    if (data.latestVersion && !isValidSemver(data.latestVersion)) {
      throw new BadRequestError(`Invalid latestVersion "${data.latestVersion}". Must be valid semver.`);
    }
    if (data.minimumVersion && !isValidSemver(data.minimumVersion)) {
      throw new BadRequestError(`Invalid minimumVersion "${data.minimumVersion}". Must be valid semver.`);
    }
    if (compareSemver(minimumVersion, latestVersion) > 0) {
      throw new BadRequestError('Minimum supported version cannot be greater than latest version.');
    }

    const whatsNew = data.whatsNew !== undefined ? normalizeWhatsNew(data.whatsNew) : existing.whatsNew;

    const updated = await prisma.appUpdate.update({
      where: { id },
      data: {
        platform,
        latestVersion,
        minimumVersion,
        forceUpdate: data.forceUpdate !== undefined ? Boolean(data.forceUpdate) : existing.forceUpdate,
        title: data.title !== undefined ? data.title.trim() : existing.title,
        message: data.message !== undefined ? data.message.trim() : existing.message,
        whatsNew,
        androidStoreUrl: data.androidStoreUrl !== undefined ? data.androidStoreUrl?.trim() || null : existing.androidStoreUrl,
        iosStoreUrl: data.iosStoreUrl !== undefined ? data.iosStoreUrl?.trim() || null : existing.iosStoreUrl,
        releaseDate: data.releaseDate !== undefined ? (data.releaseDate ? new Date(data.releaseDate) : null) : existing.releaseDate,
      },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'APP_UPDATE_EDIT',
      targetType: 'APP_UPDATE',
      targetId: id,
      previousValue: {
        platform: existing.platform,
        latestVersion: existing.latestVersion,
        minimumVersion: existing.minimumVersion,
        forceUpdate: existing.forceUpdate,
        title: existing.title,
      },
      newValue: {
        platform: updated.platform,
        latestVersion: updated.latestVersion,
        minimumVersion: updated.minimumVersion,
        forceUpdate: updated.forceUpdate,
        title: updated.title,
      },
      reason: `Updated app update v${updated.latestVersion}`,
      ipAddress,
    });

    return updated;
  }

  /**
   * Publish an app update and deactivate prior active configs for the platform.
   */
  async publishAppUpdate(adminId: string, id: string, ipAddress?: string): Promise<AppUpdate> {
    const existing = await this.getAppUpdateById(id);

    // Validate completeness before publishing
    if (!isValidSemver(existing.latestVersion) || !isValidSemver(existing.minimumVersion)) {
      throw new BadRequestError('Cannot publish update with invalid semantic version.');
    }
    if (compareSemver(existing.minimumVersion, existing.latestVersion) > 0) {
      throw new BadRequestError('Cannot publish update where minimum version exceeds latest version.');
    }
    if (
      (existing.platform === AppPlatform.ANDROID || existing.platform === AppPlatform.BOTH) &&
      !existing.androidStoreUrl
    ) {
      throw new BadRequestError('Cannot publish update: Google Play Store URL is required for Android/Both.');
    }
    if (
      (existing.platform === AppPlatform.IOS || existing.platform === AppPlatform.BOTH) &&
      !existing.iosStoreUrl
    ) {
      throw new BadRequestError('Cannot publish update: Apple App Store URL is required for iOS/Both.');
    }

    const publishedAt = new Date();

    const published = await prisma.$transaction(async (tx) => {
      // 1. Disable conflicting active updates
      await this.disableConflictingPublishedUpdates(existing.platform, id, tx as any);

      // 2. Set this update to PUBLISHED
      return tx.appUpdate.update({
        where: { id },
        data: {
          status: AppUpdateStatus.PUBLISHED,
          publishedAt,
          releaseDate: existing.releaseDate ?? publishedAt,
        },
      });
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'APP_UPDATE_PUBLISH',
      targetType: 'APP_UPDATE',
      targetId: id,
      previousValue: { status: existing.status, publishedAt: existing.publishedAt },
      newValue: { status: published.status, publishedAt: published.publishedAt },
      reason: `Published app update v${published.latestVersion} (${published.platform})`,
      ipAddress,
    });

    return published;
  }

  /**
   * Disable a published or draft app update.
   */
  async disableAppUpdate(adminId: string, id: string, ipAddress?: string): Promise<AppUpdate> {
    const existing = await this.getAppUpdateById(id);

    const disabled = await prisma.appUpdate.update({
      where: { id },
      data: {
        status: AppUpdateStatus.DISABLED,
      },
    });

    await telemetryService.recordAuditLog({
      adminId,
      action: 'APP_UPDATE_DISABLE',
      targetType: 'APP_UPDATE',
      targetId: id,
      previousValue: { status: existing.status },
      newValue: { status: disabled.status },
      reason: `Disabled app update v${disabled.latestVersion} (${disabled.platform})`,
      ipAddress,
    });

    return disabled;
  }

  /**
   * Public API: Get the currently published update configuration for a mobile platform.
   * Strips all internal admin data, IDs, secrets, and internal timestamps.
   */
  async getPublishedUpdateForPlatform(platformStr?: string): Promise<PublicAppVersionResponse | null> {
    const rawPlatform = (platformStr || '').trim().toUpperCase();
    let targetPlatform: AppPlatform = AppPlatform.ANDROID;

    if (rawPlatform === 'IOS' || rawPlatform === 'IPHONE' || rawPlatform === 'IPAD') {
      targetPlatform = AppPlatform.IOS;
    } else {
      targetPlatform = AppPlatform.ANDROID;
    }

    const activeUpdate = await prisma.appUpdate.findFirst({
      where: {
        status: AppUpdateStatus.PUBLISHED,
        platform: { in: [targetPlatform, AppPlatform.BOTH] },
      },
      orderBy: { publishedAt: 'desc' },
    });

    if (!activeUpdate) {
      return null;
    }

    // Determine platform-tailored store URL
    let storeUrl = '';
    if (targetPlatform === AppPlatform.IOS) {
      storeUrl = activeUpdate.iosStoreUrl || activeUpdate.androidStoreUrl || '';
    } else {
      storeUrl = activeUpdate.androidStoreUrl || activeUpdate.iosStoreUrl || '';
    }

    return {
      platform: targetPlatform,
      latestVersion: activeUpdate.latestVersion,
      minimumVersion: activeUpdate.minimumVersion,
      forceUpdate: activeUpdate.forceUpdate,
      title: activeUpdate.title,
      message: activeUpdate.message,
      whatsNew: activeUpdate.whatsNew,
      storeUrl,
      releaseDate: activeUpdate.releaseDate ?? activeUpdate.publishedAt,
    };
  }
}

export const adminAppUpdatesService = new AdminAppUpdatesService();
