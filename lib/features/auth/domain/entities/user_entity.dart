class UserEntity {
  final String id;
  final String name;
  final String email;
  final String targetRole;
  final String experienceYears;
  final String? avatarUrl;
  final int streakDays;
  final int weeklyGoalTarget;
  final int interviewsCompleted;
  final int averageScore;
  final int bestScore;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final String bio;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.targetRole = '',
    this.experienceYears = '',
    this.avatarUrl,
    this.streakDays = 0,
    this.weeklyGoalTarget = 0,
    this.interviewsCompleted = 0,
    this.averageScore = 0,
    this.bestScore = 0,
    this.isEmailVerified = true,
    this.isProfileComplete = false,
    this.bio = '',
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? targetRole,
    String? experienceYears,
    String? avatarUrl,
    int? streakDays,
    int? weeklyGoalTarget,
    int? interviewsCompleted,
    int? averageScore,
    int? bestScore,
    bool? isEmailVerified,
    bool? isProfileComplete,
    String? bio,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      targetRole: targetRole ?? this.targetRole,
      experienceYears: experienceYears ?? this.experienceYears,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streakDays: streakDays ?? this.streakDays,
      weeklyGoalTarget: weeklyGoalTarget ?? this.weeklyGoalTarget,
      interviewsCompleted: interviewsCompleted ?? this.interviewsCompleted,
      averageScore: averageScore ?? this.averageScore,
      bestScore: bestScore ?? this.bestScore,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      bio: bio ?? this.bio,
    );
  }
}
