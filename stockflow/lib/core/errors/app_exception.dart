/// Base class for all application exceptions.
class AppException implements Exception {
  const AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// User-friendly error message
  final String message;
  
  /// The underlying error (e.g., DioException, DatabaseException)
  final Object? originalError;
  
  /// The stack trace where the error originated
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;

  @override
  String toString() => 'NetworkException [$statusCode]: $message';
}

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

class SyncException extends AppException {
  const SyncException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}
