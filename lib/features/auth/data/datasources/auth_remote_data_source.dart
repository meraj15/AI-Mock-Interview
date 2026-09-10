import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? fullName,
  });

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout({String? refreshToken});

  Future<void> logoutAll();

  /// Sends a forgot-password request (OTP sent via email).
  Future<void> forgotPassword({required String email});

  /// Verifies password reset OTP and returns a short-lived resetToken.
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Resets the user's password using the verified resetToken.
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await apiClient.post(
      ApiConfig.registerEndpoint,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
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

  @override
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post(
      ApiConfig.forgotPasswordEndpoint,
      body: {'email': email.trim().toLowerCase()},
      requiresAuth: false,
    );
  }

  @override
  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await apiClient.post(
      ApiConfig.verifyResetOtpEndpoint,
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
      requiresAuth: false,
    );

    final data = response.data as Map<String, dynamic>;
    final innerData = data['data'] as Map<String, dynamic>? ?? data;
    return innerData['resetToken'] as String;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await apiClient.post(
      ApiConfig.resetPasswordEndpoint,
      body: {
        'resetToken': resetToken.trim(),
        'newPassword': newPassword,
      },
      requiresAuth: false,
    );
  }
}
