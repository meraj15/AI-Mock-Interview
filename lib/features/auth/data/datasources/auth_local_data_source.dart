import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> getCachedUser();
  Future<void> saveUser(UserModel user);
  Future<void> clearAuth();
  Future<void> setOnboardingComplete();
  Future<bool> isOnboardingComplete();
  Future<bool> isAuthenticated();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String keyAuth = 'interview-coach-auth';
  static const String keyOnboarding = 'interview-coach-onboarding';
  static const String keyUserId = 'interview-coach-user-id';
  static const String keyUserName = 'interview-coach-name';
  static const String keyUserEmail = 'interview-coach-email';
  static const String keyUserRole = 'interview-coach-role';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getCachedUser() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      throw CacheException('No active authentication found');
    }

    final id = sharedPreferences.getString(keyUserId);
    final email = sharedPreferences.getString(keyUserEmail);

    if (id == null || id.isEmpty || email == null || email.isEmpty) {
      throw CacheException('No valid cached user data found');
    }

    final name = sharedPreferences.getString(keyUserName) ?? (email.contains('@') ? email.split('@').first : 'User');
    final role = sharedPreferences.getString(keyUserRole) ?? '';

    return UserModel(
      id: id,
      name: name,
      email: email,
      targetRole: role,
    );
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await sharedPreferences.setBool(keyAuth, true);
    await sharedPreferences.setString(keyUserId, user.id);
    await sharedPreferences.setString(keyUserName, user.name);
    await sharedPreferences.setString(keyUserEmail, user.email);
    await sharedPreferences.setString(keyUserRole, user.targetRole);
  }

  @override
  Future<void> clearAuth() async {
    await sharedPreferences.remove(keyAuth);
    await sharedPreferences.remove(keyUserId);
    await sharedPreferences.remove(keyUserName);
    await sharedPreferences.remove(keyUserEmail);
    await sharedPreferences.remove(keyUserRole);
  }

  @override
  Future<void> setOnboardingComplete() async {
    await sharedPreferences.setBool(keyOnboarding, true);
  }

  @override
  Future<bool> isOnboardingComplete() async {
    return sharedPreferences.getBool(keyOnboarding) ?? false;
  }

  @override
  Future<bool> isAuthenticated() async {
    return sharedPreferences.getBool(keyAuth) ?? false;
  }
}
