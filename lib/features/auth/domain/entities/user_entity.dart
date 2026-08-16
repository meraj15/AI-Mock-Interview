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
  final String bio;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.targetRole = 'Flutter Developer',
    this.experienceYears = '1.2 years',
    this.avatarUrl,
    this.streakDays = 4,
    this.weeklyGoalTarget = 3,
    this.interviewsCompleted = 12,
    this.averageScore = 78,
    this.bestScore = 91,
    this.isEmailVerified = true,
    this.bio = 'Mobile software engineer passionate about clean architecture and high-performance cross-platform applications.',
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
      bio: bio ?? this.bio,
    );
  }
}
