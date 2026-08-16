class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Exception']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Exception']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Auth Exception']);
}
