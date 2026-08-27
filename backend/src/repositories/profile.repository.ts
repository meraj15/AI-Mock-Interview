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
        ...(data.firstName !== undefined && { firstName: data.firstName }),
        ...(data.lastName !== undefined && { lastName: data.lastName }),
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
        firstName: data.firstName ?? null,
        lastName: data.lastName ?? null,
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
   * Seed a minimal profile at registration time (firstName / lastName only).
   * Uses upsert so it's safe to call even if a profile already exists.
   */
  async seedProfileAtRegistration(
    userId: string,
    firstName?: string | null,
    lastName?: string | null,
  ): Promise<UserProfile> {
    return prisma.userProfile.upsert({
      where: { userId },
      update: {
        // Only set name fields if not already set
        ...(firstName && { firstName }),
        ...(lastName && { lastName }),
      },
      create: {
        userId,
        firstName: firstName ?? null,
        lastName: lastName ?? null,
        skills: [],
        education: [],
        projects: [],
        certifications: [],
      },
    });
  }
}

export const profileRepository = new ProfileRepository();
