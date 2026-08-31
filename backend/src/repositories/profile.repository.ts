import { prisma } from '../config/database';
import { UserProfile } from '@prisma/client';
import { UpdateProfileInput } from '../validators/profile.validator';

export class ProfileRepository {
  async getProfileByUserId(userId: string): Promise<UserProfile | null> {
    return prisma.userProfile.findUnique({
      where: { userId },
    });
  }

  async upsertProfile(userId: string, data: UpdateProfileInput): Promise<UserProfile> {
    // Serialise JSON array fields — Prisma requires JsonValue (plain JS value)
    const educationJson = data.education !== undefined ? (data.education as object[]) : undefined;
    const projectsJson = data.projects !== undefined ? (data.projects as object[]) : undefined;
    const certificationsJson = data.certifications !== undefined ? (data.certifications as object[]) : undefined;

    return prisma.userProfile.upsert({
      where: { userId },
      update: {
        ...(data.fullName !== undefined && { fullName: data.fullName }),
        ...(data.phone !== undefined && { phone: data.phone }),
        ...(data.targetRole !== undefined && { targetRole: data.targetRole }),
        ...(data.experienceYears !== undefined && { experienceYears: data.experienceYears }),
        ...(data.bio !== undefined && { bio: data.bio }),
        ...(data.skills !== undefined && { skills: data.skills }),
        ...(educationJson !== undefined && { education: educationJson }),
        ...(projectsJson !== undefined && { projects: projectsJson }),
        ...(certificationsJson !== undefined && { certifications: certificationsJson }),
      },
      create: {
        userId,
        fullName: data.fullName ?? null,
        phone: data.phone ?? null,
        targetRole: data.targetRole ?? null,
        experienceYears: data.experienceYears ?? null,
        bio: data.bio ?? null,
        skills: data.skills ?? [],
        education: educationJson ?? [],
        projects: projectsJson ?? [],
        certifications: certificationsJson ?? [],
      },
    });
  }

  /**
   * Seed a minimal profile at registration time (fullName only).
   * Uses upsert so it's safe to call even if a profile already exists.
   */
  async seedProfileAtRegistration(
    userId: string,
    fullName?: string | null,
  ): Promise<UserProfile> {
    return prisma.userProfile.upsert({
      where: { userId },
      update: {
        ...(fullName && { fullName }),
      },
      create: {
        userId,
        fullName: fullName ?? null,
        skills: [],
        education: [],
        projects: [],
        certifications: [],
      },
    });
  }
}

export const profileRepository = new ProfileRepository();
