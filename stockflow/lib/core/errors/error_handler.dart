import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import 'app_exception.dart';

/// Global error handler to intercept and process all app errors.
class ErrorHandler {
  ErrorHandler._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void handle(Object error, StackTrace stackTrace) {
    // 1. Log the error
    LoggerService.e('Unhandled error intercepted', error: error, stackTrace: stackTrace, tag: 'ERROR_HANDLER');

    // 2. Map to AppException
    final appException = _mapToAppException(error, stackTrace);

    // 3. Show user-friendly message
    _showErrorSnackBar(appException.message);
  }

  static AppException _mapToAppException(Object error, StackTrace stackTrace) {
    if (error is AppException) {
      return error;
    }

    // Add specific mappings here (e.g., DioException, Drift exception mappings)
    // For now, return a generic AppException
    return AppException(
      message: 'An unexpected error occurred. Please try again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static void _showErrorSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      LoggerService.w('Could not show SnackBar, context is null or unmounted.', tag: 'ERROR_HANDLER');
    }
  }
}
