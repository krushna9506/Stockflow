import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../errors/error_handler.dart';
import 'logger_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  void showSuccess(String message) {
    _showSnackBar(message, isError: false);
  }

  void showError(String message) {
    _showSnackBar(message, isError: true);
  }

  void showInfo(String message) {
    _showSnackBar(message, isInfo: true);
  }

  void _showSnackBar(String message, {bool isError = false, bool isInfo = false}) {
    final context = ErrorHandler.navigatorKey.currentContext;
    if (context == null) {
      LoggerService.w('Tried to show notification without context: $message', tag: 'NOTIFICATION');
      return;
    }

    final cs = Theme.of(context).colorScheme;
    Color bgColor = cs.inverseSurface;
    Color textColor = cs.onInverseSurface;
    IconData icon = Icons.info_outline;

    if (isError) {
      bgColor = cs.errorContainer;
      textColor = cs.onErrorContainer;
      icon = Icons.error_outline;
    } else if (isInfo) {
      bgColor = cs.primaryContainer;
      textColor = cs.onPrimaryContainer;
      icon = Icons.info_outline;
    } else {
      bgColor = cs.tertiaryContainer;
      textColor = cs.onTertiaryContainer;
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
