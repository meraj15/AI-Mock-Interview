import { z } from 'zod';
import { isValidSemver, compareSemver } from '../utils/semver';

const platformEnum = z.enum(['ANDROID', 'IOS', 'BOTH']);

export const createAppUpdateSchema = z.object({
  platform: platformEnum,
  latestVersion: z
    .string({ required_error: 'Latest version is required' })
    .trim()
    .refine((v) => isValidSemver(v), {
      message: 'Latest version must follow semantic versioning (e.g. 1.5.0)',
    }),
  minimumVersion: z
    .string({ required_error: 'Minimum supported version is required' })
    .trim()
    .refine((v) => isValidSemver(v), {
      message: 'Minimum supported version must follow semantic versioning (e.g. 1.4.0)',
    }),
  forceUpdate: z.boolean().optional().default(false),
  title: z
    .string({ required_error: 'Title is required' })
    .trim()
    .min(1, 'Title cannot be empty')
    .max(100, 'Title cannot exceed 100 characters'),
  message: z
    .string({ required_error: 'Message is required' })
    .trim()
    .min(1, 'Message cannot be empty')
    .max(2000, 'Message cannot exceed 2000 characters'),
  whatsNew: z
    .union([z.array(z.string()), z.string()])
    .optional()
    .default([]),
  androidStoreUrl: z.string().trim().optional().nullable(),
  iosStoreUrl: z.string().trim().optional().nullable(),
  releaseDate: z.string().datetime().optional().nullable(),
  publishNow: z.boolean().optional().default(false),
}).superRefine((data, ctx) => {
  // Validate minimumVersion <= latestVersion
  if (isValidSemver(data.minimumVersion) && isValidSemver(data.latestVersion)) {
    try {
      if (compareSemver(data.minimumVersion, data.latestVersion) > 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['minimumVersion'],
          message: 'Minimum supported version cannot be greater than latest version',
        });
      }
    } catch {
      // Ignored if invalid
    }
  }

  // Validate Android Store URL when required
  if (data.platform === 'ANDROID' || data.platform === 'BOTH') {
    if (!data.androidStoreUrl || data.androidStoreUrl.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['androidStoreUrl'],
        message: 'Google Play Store URL is required for Android and Both platforms',
      });
    } else {
      try {
        new URL(data.androidStoreUrl);
      } catch {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['androidStoreUrl'],
          message: 'Google Play Store URL must be a valid URL',
        });
      }
    }
  }

  // Validate iOS Store URL when required
  if (data.platform === 'IOS' || data.platform === 'BOTH') {
    if (!data.iosStoreUrl || data.iosStoreUrl.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['iosStoreUrl'],
        message: 'Apple App Store URL is required for iOS and Both platforms',
      });
    } else {
      try {
        new URL(data.iosStoreUrl);
      } catch {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['iosStoreUrl'],
          message: 'Apple App Store URL must be a valid URL',
        });
      }
    }
  }
});

export const updateAppUpdateSchema = z.object({
  platform: platformEnum.optional(),
  latestVersion: z
    .string()
    .trim()
    .refine((v) => isValidSemver(v), {
      message: 'Latest version must follow semantic versioning (e.g. 1.5.0)',
    })
    .optional(),
  minimumVersion: z
    .string()
    .trim()
    .refine((v) => isValidSemver(v), {
      message: 'Minimum supported version must follow semantic versioning (e.g. 1.4.0)',
    })
    .optional(),
  forceUpdate: z.boolean().optional(),
  title: z
    .string()
    .trim()
    .min(1, 'Title cannot be empty')
    .max(100, 'Title cannot exceed 100 characters')
    .optional(),
  message: z
    .string()
    .trim()
    .min(1, 'Message cannot be empty')
    .max(2000, 'Message cannot exceed 2000 characters')
    .optional(),
  whatsNew: z
    .union([z.array(z.string()), z.string()])
    .optional(),
  androidStoreUrl: z.string().trim().optional().nullable(),
  iosStoreUrl: z.string().trim().optional().nullable(),
  releaseDate: z.string().datetime().optional().nullable(),
});

export function normalizeWhatsNew(input: unknown): string[] {
  if (Array.isArray(input)) {
    return input
      .map((item) => (typeof item === 'string' ? item.trim() : String(item).trim()))
      .filter((item) => item.length > 0);
  }
  if (typeof input === 'string') {
    return input
      .split('\n')
      .map((line) => line.trim().replace(/^[•\-\*\u2713]\s*/, '')) // strip bullet chars if desired
      .filter((line) => line.length > 0);
  }
  return [];
}
