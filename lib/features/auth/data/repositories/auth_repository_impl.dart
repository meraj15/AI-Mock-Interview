import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.tokenStorage,
  });

  @override
  Future<UserEntity> getAuthState() async {
    final hasToken = await tokenStorage.hasTokens();
    if (!hasToken) {
      final isLocalAuth = await localDataSource.isAuthenticated();
      if (!isLocalAuth) {
        throw AuthException('Not authenticated');
      }
    }

    try {
      // Validate session with backend
      final remoteUser = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(remoteUser);
      await localDataSource.setOnboardingComplete();
      return remoteUser;
    } catch (e) {
      if (e is AuthException) {
        await tokenStorage.clearTokens();
        await localDataSource.clearAuth();
        rethrow;
      }
      // If offline/network failure, return cached local user if available
      return await localDataSource.getCachedUser();
    }
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    final response = await remoteDataSource.login(
      email: email,
      password: password,
    );

    // Save tokens securely
    if (response.accessToken.isNotEmpty && response.refreshToken.isNotEmpty) {
      await tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }

    final user = response.user ??
        UserModel(
          id: 'usr_login',
          name: email.contains('@') ? email.split('@').first : 'Candidate',
          email: email,
          isProfileComplete: true,
        );

    // Cache user locally and set onboarding complete
    await localDataSource.saveUser(user);
    await localDataSource.setOnboardingComplete();

    return user;
  }

  @override
  Future<UserEntity> signUp(String name, String email, String password) async {
    final response = await remoteDataSource.register(
      email: email,
      password: password,
      fullName: name,
    );

    // Save tokens securely
    if (response.accessToken.isNotEmpty && response.refreshToken.isNotEmpty) {
      await tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }

    final user = response.user ??
        UserModel(
          id: 'usr_registered',
          name: name.isNotEmpty ? name : (email.contains('@') ? email.split('@').first : 'Candidate'),
          email: email,
          isProfileComplete: false,
        );

    // Cache user locally and set onboarding complete
    await localDataSource.saveUser(user);
    await localDataSource.setOnboardingComplete();

    return user;
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    await remoteDataSource.logout(refreshToken: refreshToken);
    await tokenStorage.clearTokens();
    await localDataSource.clearAuth();
  }

  @override
  Future<void> logoutAll() async {
    await remoteDataSource.logoutAll();
    await tokenStorage.clearTokens();
    await localDataSource.clearAuth();
  }

  @override
  Future<void> completeOnboarding() async {
    await localDataSource.setOnboardingComplete();
  }

  @override
  Future<bool> isOnboardingComplete() async {
    return await localDataSource.isOnboardingComplete();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    return await remoteDataSource.verifyResetOtp(
      email: email,
      otp: otp,
    );
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await remoteDataSource.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}
