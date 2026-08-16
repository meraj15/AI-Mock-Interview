import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> getAuthState();
  Future<UserEntity> signIn(String email, String password);
  Future<UserEntity> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<void> completeOnboarding();
  Future<void> sendPasswordReset(String email);
}
