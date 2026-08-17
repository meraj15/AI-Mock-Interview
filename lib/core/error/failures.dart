abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final String? code;
  const ServerFailure([super.message = 'Something went wrong. Please try again.', this.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Unable to connect to the server. Please check your internet connection.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure occurred']);
}

class AuthFailure extends Failure {
  final String? code;
  const AuthFailure([super.message = 'Authentication error', this.code]);
}

class ValidationFailure extends Failure {
  final List<String> errors;
  const ValidationFailure([super.message = 'Validation failed', this.errors = const []]);
}
