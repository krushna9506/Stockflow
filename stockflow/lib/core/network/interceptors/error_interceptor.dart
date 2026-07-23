import 'package:dio/dio.dart';
import '../../errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException appException;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appException = NetworkException(
          message: 'Connection timed out. Please check your internet connection.',
          originalError: err,
          stackTrace: err.stackTrace,
        );
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          appException = AuthException(
            message: 'Session expired. Please log in again.',
            originalError: err,
            stackTrace: err.stackTrace,
          );
        } else if (statusCode == 422 || statusCode == 400) {
          appException = ValidationException(
            message: _extractErrorMessage(err.response) ?? 'Validation failed.',
            originalError: err,
            stackTrace: err.stackTrace,
          );
        } else {
          appException = NetworkException(
            message: _extractErrorMessage(err.response) ?? 'Server error occurred ($statusCode).',
            statusCode: statusCode,
            originalError: err,
            stackTrace: err.stackTrace,
          );
        }
        break;
      case DioExceptionType.connectionError:
        appException = NetworkException(
          message: 'Failed to connect to the server. Please check your network.',
          originalError: err,
          stackTrace: err.stackTrace,
        );
        break;
      default:
        appException = NetworkException(
          message: 'An unexpected network error occurred.',
          originalError: err,
          stackTrace: err.stackTrace,
        );
        break;
    }

    // We pass the new exception so downstream error handlers get the typed AppException
    handler.next(err.copyWith(error: appException));
  }

  String? _extractErrorMessage(Response? response) {
    if (response?.data is Map) {
      return response?.data['message'] as String? ?? response?.data['detail'] as String?;
    }
    return null;
  }
}
