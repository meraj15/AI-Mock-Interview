import 'package:shared_preferences/shared_preferences.dart';
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
  static const String keyUserName = 'interview-coach-name';
  static const String keyUserEmail = 'interview-coach-email';
  static const String keyUserRole = 'interview-coach-role';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getCachedUser() async {
    final name = sharedPreferences.getString(keyUserName) ?? 'Meraj Khan';
    final email = sharedPreferences.getString(keyUserEmail) ?? 'meraj.khan@email.com';
    final role = sharedPreferences.getString(keyUserRole) ?? 'Flutter Developer';

    return UserModel(
      id: 'usr_1',
      name: name,
      email: email,
      targetRole: role,
    );
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await sharedPreferences.setBool(keyAuth, true);
    await sharedPreferences.setString(keyUserName, user.name);
    await sharedPreferences.setString(keyUserEmail, user.email);
    await sharedPreferences.setString(keyUserRole, user.targetRole);
  }

  @override
  Future<void> clearAuth() async {
    await sharedPreferences.remove(keyAuth);
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
