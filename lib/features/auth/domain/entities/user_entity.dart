class UserEntity {
  final String id;
  final String name;
  final String email;
  final String targetRole;
  final bool isOnboarded;
  final bool isAuthenticated;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.targetRole = 'Flutter Developer',
    this.isOnboarded = false,
    this.isAuthenticated = false,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? targetRole,
    bool? isOnboarded,
    bool? isAuthenticated,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      targetRole: targetRole ?? this.targetRole,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
