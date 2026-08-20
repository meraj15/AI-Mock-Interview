import { ProfileRepository, profileRepository } from '../repositories/profile.repository';
import { UpdateProfileInput } from '../validators/profile.validator';
import { UserProfile } from '@prisma/client';

export class ProfileService {
  constructor(private readonly repo: ProfileRepository = profileRepository) {}

  async getProfile(userId: string): Promise<UserProfile | null> {
    return this.repo.getProfileByUserId(userId);
  }

  async updateProfile(userId: string, data: UpdateProfileInput): Promise<UserProfile> {
    return this.repo.upsertProfile(userId, data);
  }
}

export const profileService = new ProfileService();
