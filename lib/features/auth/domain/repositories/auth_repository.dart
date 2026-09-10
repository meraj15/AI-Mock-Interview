import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> getAuthState();
  Future<UserEntity> signIn(String email, String password);

  /// Registers user, stores tokens, and immediately returns authenticated [UserEntity].
  Future<UserEntity> signUp(String name, String email, String password);

  Future<void> signOut();
  Future<void> logoutAll();
  Future<void> completeOnboarding();
  Future<bool> isOnboardingComplete();

  /// Requests a password reset OTP — OTP is sent via email.
  Future<void> forgotPassword(String email);

  /// Verifies password reset OTP and returns a short-lived resetToken.
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Updates password using the verified [resetToken].
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
