import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<UserEntity> getAuthState() async {
    final isAuth = await localDataSource.isAuthenticated();
    if (!isAuth) {
      throw Exception('Not authenticated');
    }
    return await localDataSource.getCachedUser();
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    final user = UserModel(
      id: 'usr_1',
      name: 'Meraj Khan',
      email: email,
      targetRole: 'Flutter Developer',
      experienceYears: '1.2 years',
    );
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<UserEntity> signUp(String name, String email, String password) async {
    final user = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      targetRole: 'Flutter Developer',
      experienceYears: '1.0 years',
    );
    await localDataSource.saveUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await localDataSource.clearAuth();
  }

  @override
  Future<void> completeOnboarding() async {
    await localDataSource.setOnboardingComplete();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}
