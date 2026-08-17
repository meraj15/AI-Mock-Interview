import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout({String? refreshToken});

  Future<void> logoutAll();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final response = await apiClient.post(
      ApiConfig.registerEndpoint,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      },
      requiresAuth: false,
    );

    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConfig.loginEndpoint,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );

    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get(
      ApiConfig.meEndpoint,
      requiresAuth: true,
    );

    final data = response.data as Map<String, dynamic>;
    final userJson = data.containsKey('user') ? data['user'] as Map<String, dynamic> : data;
    return UserModel.fromJson(userJson);
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    try {
      final Map<String, dynamic> payload = {};
      if (refreshToken != null) {
        payload['refreshToken'] = refreshToken;
      }
      await apiClient.post(
        ApiConfig.logoutEndpoint,
        body: payload,
        requiresAuth: true,
      );
    } catch (_) {
      // Graceful local cleanup even if remote call fails
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await apiClient.post(
        ApiConfig.logoutAllEndpoint,
        requiresAuth: true,
      );
    } catch (_) {
      // Graceful local cleanup even if remote call fails
    }
  }
}
