import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.targetRole,
    super.isOnboarded,
    super.isAuthenticated,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      targetRole: entity.targetRole,
      isOnboarded: entity.isOnboarded,
      isAuthenticated: entity.isAuthenticated,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'user_1',
      name: json['name'] as String? ?? 'Meraj Khan',
      email: json['email'] as String? ?? 'meraj.khan@email.com',
      targetRole: json['targetRole'] as String? ?? 'Flutter Developer',
      isOnboarded: json['isOnboarded'] as bool? ?? false,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'targetRole': targetRole,
      'isOnboarded': isOnboarded,
      'isAuthenticated': isAuthenticated,
    };
  }
}
