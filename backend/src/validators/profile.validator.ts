import { z } from 'zod';

export const updateProfileSchema = z.object({
  firstName: z.string().trim().max(50, 'First name must not exceed 50 characters').nullable().optional(),
  lastName: z.string().trim().max(50, 'Last name must not exceed 50 characters').nullable().optional(),
  phone: z.string().trim().max(20, 'Phone must not exceed 20 characters').nullable().optional(),
  targetRole: z.string().trim().max(100, 'Target role must not exceed 100 characters').nullable().optional(),
  experienceYears: z
    .number({ invalid_type_error: 'Experience years must be a number' })
    .min(0, 'Experience years cannot be negative')
    .max(60, 'Experience years must be 60 or less')
    .nullable()
    .optional(),
  bio: z.string().trim().max(1000, 'Bio must not exceed 1000 characters').nullable().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
