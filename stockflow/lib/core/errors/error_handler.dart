import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/logger_service.dart';
import 'app_exception.dart';

/// Global error handler to intercept and process all app errors.
class ErrorHandler {
  ErrorHandler._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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

    if (error is DioException) {
      String message = 'Network error occurred. Please check your internet connection.';

      if (error.response != null && error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('message') && data['message'] != null) {
          message = data['message'].toString();
        } else if (error.response?.statusCode == 401) {
          message = 'Invalid email or password. Please try again.';
        } else if (error.response?.statusCode == 400) {
          message = 'Bad request. Please check your input details.';
        } else if (error.response?.statusCode == 404) {
          message = 'Requested service or user not found.';
        } else if (error.response?.statusCode == 500) {
          message = 'Server error occurred. Please try again later.';
        }
      } else if (error.type == DioExceptionType.connectionTimeout ||
                 error.type == DioExceptionType.sendTimeout ||
                 error.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out. Please check your network connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        message = 'Cannot connect to server. Please check your internet connection.';
      }

      return AppException(
        message: message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      message: error.toString().replaceAll('Exception: ', ''),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static void _showErrorSnackBar(String message) {
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      LoggerService.w('Could not show SnackBar, context is null or unmounted.', tag: 'ERROR_HANDLER');
    }
  }
}
