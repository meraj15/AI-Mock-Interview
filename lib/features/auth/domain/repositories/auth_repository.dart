import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> getAuthState();
  Future<UserEntity> signIn(String email, String password);
  Future<UserEntity> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<void> logoutAll();
  Future<void> completeOnboarding();
  Future<bool> isOnboardingComplete();

  /// Requests a password reset OTP for [email].
  /// Returns the OTP (dev mode only — empty string in production).
  Future<String> forgotPassword(String email);

  /// Verifies [otp] and sets [newPassword] for the account with [email].
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
