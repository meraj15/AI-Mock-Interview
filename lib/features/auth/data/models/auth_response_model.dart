import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String? message;
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.success,
    this.message,
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final userJson = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;

    return AuthResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      user: UserModel.fromJson(userJson),
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
    );
  }
}
