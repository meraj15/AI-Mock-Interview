import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

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
    await tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // Cache user locally and set onboarding complete
    await localDataSource.saveUser(response.user);
    await localDataSource.setOnboardingComplete();

    return response.user;
  }

  @override
  Future<UserEntity> signUp(String name, String email, String password) async {
    final response = await remoteDataSource.register(
      email: email,
      password: password,
      firstName: name,
    );

    // Save tokens securely
    await tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // Cache user locally and set onboarding complete
    await localDataSource.saveUser(response.user);
    await localDataSource.setOnboardingComplete();

    return response.user;
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
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}
