import { prisma } from '../../config/database';
import { telemetryService } from '../telemetry.service';
import { config } from '../../config';

export interface AppSettings {
  freeInterviewLimit: number;
  proInterviewLimit: number;
  freeResumeScanLimit: number;
  proResumeScanLimit: number;
  voiceEntitlementEnabled: boolean;
  liveTimeoutMs: number;
  aiPricingInputPerMillionPaise: number;
  aiPricingOutputPerMillionPaise: number;
  geminiModel: string;
}

const DEFAULT_SETTINGS: AppSettings = {
  freeInterviewLimit: 2,
  proInterviewLimit: 30,
  freeResumeScanLimit: 1,
  proResumeScanLimit: 5,
  voiceEntitlementEnabled: true,
  liveTimeoutMs: config.ai.liveTimeoutMs || 12000,
  aiPricingInputPerMillionPaise: 1275, // ₹12.75
  aiPricingOutputPerMillionPaise: 5100, // ₹51.00
  geminiModel: config.ai.livePrimaryModel || 'gemini-3.8-flash',
};

export class AdminSettingsService {
  async getSettings(): Promise<AppSettings> {
    const configs = await prisma.systemConfig.findMany();
    const map = new Map(configs.map((c: any) => [c.key, c.value]));

    return {
      freeInterviewLimit: (map.get('freeInterviewLimit') as number) ?? DEFAULT_SETTINGS.freeInterviewLimit,
      proInterviewLimit: (map.get('proInterviewLimit') as number) ?? DEFAULT_SETTINGS.proInterviewLimit,
      freeResumeScanLimit: (map.get('freeResumeScanLimit') as number) ?? DEFAULT_SETTINGS.freeResumeScanLimit,
      proResumeScanLimit: (map.get('proResumeScanLimit') as number) ?? DEFAULT_SETTINGS.proResumeScanLimit,
      voiceEntitlementEnabled: (map.get('voiceEntitlementEnabled') as boolean) ?? DEFAULT_SETTINGS.voiceEntitlementEnabled,
      liveTimeoutMs: (map.get('liveTimeoutMs') as number) ?? DEFAULT_SETTINGS.liveTimeoutMs,
      aiPricingInputPerMillionPaise: (map.get('aiPricingInputPerMillionPaise') as number) ?? DEFAULT_SETTINGS.aiPricingInputPerMillionPaise,
      aiPricingOutputPerMillionPaise: (map.get('aiPricingOutputPerMillionPaise') as number) ?? DEFAULT_SETTINGS.aiPricingOutputPerMillionPaise,
      geminiModel: (map.get('geminiModel') as string) ?? DEFAULT_SETTINGS.geminiModel,
    };
  }

  async updateSettings(
    adminId: string,
    updates: Partial<AppSettings>,
    reason: string,
    ipAddress?: string
  ): Promise<{ success: boolean; message: string; settings: AppSettings }> {
    const currentSettings = await this.getSettings();

    for (const [key, val] of Object.entries(updates)) {
      if (val !== undefined) {
        await prisma.systemConfig.upsert({
          where: { key },
          create: {
            key,
            value: val as any,
            updatedBy: adminId,
          },
          update: {
            value: val as any,
            updatedBy: adminId,
          },
        });
      }
    }

    await telemetryService.recordAuditLog({
      adminId,
      action: 'SETTINGS_UPDATE',
      targetType: 'SYSTEM',
      targetId: 'CONFIGURATION',
      previousValue: currentSettings,
      newValue: updates,
      reason: reason || 'Admin updated operational settings',
      ipAddress,
    });

    const newSettings = await this.getSettings();
    return {
      success: true,
      message: 'Settings updated successfully',
      settings: newSettings,
    };
  }
}

export const adminSettingsService = new AdminSettingsService();
