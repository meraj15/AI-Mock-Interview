import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasTokens();
}

class TokenStorageImpl implements TokenStorage {
  final SharedPreferences sharedPreferences;

  static const String _keyAccessToken = 'secure_ic_access_token';
  static const String _keyRefreshToken = 'secure_ic_refresh_token';

  TokenStorageImpl({required this.sharedPreferences});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await sharedPreferences.setString(_keyAccessToken, accessToken);
    await sharedPreferences.setString(_keyRefreshToken, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    final token = sharedPreferences.getString(_keyAccessToken);
    return (token != null && token.isNotEmpty) ? token : null;
  }

  @override
  Future<String?> getRefreshToken() async {
    final token = sharedPreferences.getString(_keyRefreshToken);
    return (token != null && token.isNotEmpty) ? token : null;
  }

  @override
  Future<void> clearTokens() async {
    await sharedPreferences.remove(_keyAccessToken);
    await sharedPreferences.remove(_keyRefreshToken);
  }

  @override
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null;
  }
}
