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
    super.isProfileComplete,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    // If name is not provided in backend User model, generate a friendly initial name from email
    final defaultName = email.contains('@') ? email.split('@').first : 'User';
    final rawName = json['fullName'] as String? ?? json['name'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : defaultName;

    return UserModel(
      id: json['id'] as String? ?? '',
      name: name,
      email: email,
      targetRole: json['targetRole'] as String? ?? '',
      experienceYears: json['experienceYears'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      streakDays: json['streakDays'] as int? ?? 0,
      weeklyGoalTarget: json['weeklyGoalTarget'] as int? ?? 0,
      interviewsCompleted: json['interviewsCompleted'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      isEmailVerified: json['isVerified'] as bool? ?? (json['isEmailVerified'] as bool? ?? true),
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      bio: json['bio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
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
      'isProfileComplete': isProfileComplete,
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
      isProfileComplete: entity.isProfileComplete,
      bio: entity.bio,
    );
  }
}
