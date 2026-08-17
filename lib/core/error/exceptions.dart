class ServerException implements Exception {
  final String message;
  final String? code;
  ServerException([this.message = 'Server Exception', this.code]);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Unable to connect to the server. Please check your internet connection.']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Exception']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException([this.message = 'Authentication Exception', this.code]);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final List<String> errors;
  ValidationException([this.message = 'Validation Exception', this.errors = const []]);

  @override
  String toString() => message;
}
