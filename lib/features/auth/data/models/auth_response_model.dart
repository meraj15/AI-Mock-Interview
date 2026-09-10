import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String? message;
  final UserModel? user;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.success,
    this.message,
    this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // If json has a nested 'data' map, unwrap it; otherwise use json directly
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    // Resolve user object: check data['user'], json['user'], or data itself if it contains user fields
    Map<String, dynamic>? userMap;
    if (data['user'] is Map<String, dynamic>) {
      userMap = data['user'] as Map<String, dynamic>;
    } else if (json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
    } else if (data.containsKey('id') || data.containsKey('email')) {
      userMap = data;
    }

    final accessToken = (data['accessToken'] ?? json['accessToken']) as String? ?? '';
    final refreshToken = (data['refreshToken'] ?? json['refreshToken']) as String? ?? '';

    return AuthResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      user: userMap != null ? UserModel.fromJson(userMap) : null,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
