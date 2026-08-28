import { ProfileRepository, profileRepository } from '../repositories/profile.repository';
import {
  UpdateProfileInput,
  EducationItem,
  ProjectItem,
  CertificationItem,
} from '../validators/profile.validator';
import { UserProfile } from '@prisma/client';

export class ProfileService {
  constructor(private readonly repo: ProfileRepository = profileRepository) {}

  async getProfile(userId: string): Promise<UserProfile | null> {
    return this.repo.getProfileByUserId(userId);
  }

  async updateProfile(userId: string, data: UpdateProfileInput): Promise<UserProfile> {
    if (data.fullName !== undefined) {
      const trimmed = (data.fullName ?? '').trim();
      if (trimmed.length > 0) {
        const parts = trimmed.split(/\s+/);
        data.firstName = parts[0];
        data.lastName = parts.length > 1 ? parts.slice(1).join(' ') : '';
      } else {
        data.firstName = null;
        data.lastName = null;
      }
    }
    return this.repo.upsertProfile(userId, data);
  }

  /**
   * Merge resume-extracted data into the user's existing profile.
   * Existing user-provided values are preserved; only empty/null fields are filled.
   */
  async mergeResumeProfile(userId: string, resumeData: Partial<UpdateProfileInput>): Promise<UserProfile> {
    const existing = await this.repo.getProfileByUserId(userId);

    const existingEducation = existing?.education as unknown as EducationItem[] | null;
    const existingProjects = existing?.projects as unknown as ProjectItem[] | null;
    const existingCertifications = existing?.certifications as unknown as CertificationItem[] | null;

    const merged: UpdateProfileInput = {
      // Preserve existing values; only fill from resume if field is empty
      targetRole: existing?.targetRole || resumeData.targetRole,
      experienceYears: existing?.experienceYears ?? resumeData.experienceYears,
      bio: existing?.bio || resumeData.bio,
      // Skills: merge unique values from both sources
      skills: mergeArrays(existing?.skills ?? [], resumeData.skills ?? []),
      // JSON arrays: use existing if non-empty, else use resume data
      education: (existingEducation && existingEducation.length > 0)
        ? existingEducation
        : (resumeData.education ?? []),
      projects: (existingProjects && existingProjects.length > 0)
        ? existingProjects
        : (resumeData.projects ?? []),
      certifications: (existingCertifications && existingCertifications.length > 0)
        ? existingCertifications
        : (resumeData.certifications ?? []),
    };

    return this.repo.upsertProfile(userId, merged);
  }

  /**
   * Seed a minimal profile immediately after user registration.
   */
  async seedProfileAtRegistration(
    userId: string,
    firstName?: string | null,
    lastName?: string | null,
  ): Promise<UserProfile> {
    return this.repo.seedProfileAtRegistration(userId, firstName, lastName);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function mergeArrays(existing: string[], incoming: string[]): string[] {
  const combined = [...existing];
  for (const item of incoming) {
    if (item && !combined.includes(item)) {
      combined.push(item);
    }
  }
  return combined;
}

export const profileService = new ProfileService();
