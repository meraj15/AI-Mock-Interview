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
    return prisma.userProfile.upsert({
      where: { userId },
      update: {
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        targetRole: data.targetRole,
        experienceYears: data.experienceYears,
        bio: data.bio,
      },
      create: {
        userId,
        firstName: data.firstName,
        lastName: data.lastName,
        phone: data.phone,
        targetRole: data.targetRole,
        experienceYears: data.experienceYears,
        bio: data.bio,
      },
    });
  }
}

export const profileRepository = new ProfileRepository();
