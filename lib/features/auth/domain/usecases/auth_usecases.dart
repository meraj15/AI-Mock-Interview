import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetAuthStateUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;
  GetAuthStateUseCase(this.repository);

  @override
  Future<UserEntity> call(NoParams params) {
    return repository.getAuthState();
  }
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<UserEntity> call(SignInParams params) {
    return repository.signIn(params.email, params.password);
  }
}

class SignInParams {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<UserEntity> call(SignUpParams params) {
    return repository.signUp(params.name, params.email, params.password);
  }
}

class SignUpParams {
  final String name;
  final String email;
  final String password;
  const SignUpParams({required this.name, required this.email, required this.password});
}

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.signOut();
  }
}

class CompleteOnboardingUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  CompleteOnboardingUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.completeOnboarding();
  }
}

class CheckOnboardingUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;
  CheckOnboardingUseCase(this.repository);

  @override
  Future<bool> call(NoParams params) {
    return repository.isOnboardingComplete();
  }
}

class ForgotPasswordUseCase {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);

  Future<String> call(String email) {
    return repository.forgotPassword(email);
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return repository.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }
}
