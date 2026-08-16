import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.targetRole,
    super.experienceYears,
    super.avatarUrl,
    super.streakDays,
    super.weeklyGoalTarget,
    super.interviewsCompleted,
    super.averageScore,
    super.bestScore,
    super.isEmailVerified,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'usr_1',
      name: json['name'] as String? ?? 'Meraj Khan',
      email: json['email'] as String? ?? 'meraj.khan@email.com',
      targetRole: json['targetRole'] as String? ?? 'Flutter Developer',
      experienceYears: json['experienceYears'] as String? ?? '1.2 years',
      avatarUrl: json['avatarUrl'] as String?,
      streakDays: json['streakDays'] as int? ?? 4,
      weeklyGoalTarget: json['weeklyGoalTarget'] as int? ?? 3,
      interviewsCompleted: json['interviewsCompleted'] as int? ?? 12,
      averageScore: json['averageScore'] as int? ?? 78,
      bestScore: json['bestScore'] as int? ?? 91,
      isEmailVerified: json['isEmailVerified'] as bool? ?? true,
      bio: json['bio'] as String? ??
          'Mobile software engineer passionate about clean architecture and high-performance cross-platform applications.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'targetRole': targetRole,
      'experienceYears': experienceYears,
      'avatarUrl': avatarUrl,
      'streakDays': streakDays,
      'weeklyGoalTarget': weeklyGoalTarget,
      'interviewsCompleted': interviewsCompleted,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'isEmailVerified': isEmailVerified,
      'bio': bio,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      targetRole: entity.targetRole,
      experienceYears: entity.experienceYears,
      avatarUrl: entity.avatarUrl,
      streakDays: entity.streakDays,
      weeklyGoalTarget: entity.weeklyGoalTarget,
      interviewsCompleted: entity.interviewsCompleted,
      averageScore: entity.averageScore,
      bestScore: entity.bestScore,
      isEmailVerified: entity.isEmailVerified,
      bio: entity.bio,
    );
  }
}
