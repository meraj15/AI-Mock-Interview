import { z } from 'zod';

// ── Education item schema ─────────────────────────────────────────────────────
const educationItemSchema = z.object({
  degree: z.string().trim().max(200).optional().default(''),
  institution: z.string().trim().max(200).optional().default(''),
  year: z.string().trim().max(10).optional().default(''),
});

// ── Project item schema ───────────────────────────────────────────────────────
const projectItemSchema = z.object({
  name: z.string().trim().max(200).optional().default(''),
  description: z.string().trim().max(1000).optional().default(''),
  technologies: z.array(z.string().trim()).optional().default([]),
});

// ── Certification item schema ─────────────────────────────────────────────────
const certificationItemSchema = z.object({
  name: z.string().trim().max(200).optional().default(''),
  issuer: z.string().trim().max(200).optional().default(''),
  year: z.string().trim().max(10).optional().default(''),
});

// ── Full update profile schema ────────────────────────────────────────────────
export const updateProfileSchema = z.object({
  fullName: z.string().trim().max(100, 'Full name must not exceed 100 characters').nullable().optional(),
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
  // Extended unified profile fields
  skills: z.array(z.string().trim().max(100)).max(100, 'Too many skills').optional(),
  education: z.array(educationItemSchema).optional(),
  projects: z.array(projectItemSchema).optional(),
  certifications: z.array(certificationItemSchema).optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type EducationItem = z.infer<typeof educationItemSchema>;
export type ProjectItem = z.infer<typeof projectItemSchema>;
export type CertificationItem = z.infer<typeof certificationItemSchema>;
