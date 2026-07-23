import 'package:logger/logger.dart';
import '../config/env_config.dart';

/// Centralized logging service wrapping the `logger` package.
class LoggerService {
  LoggerService._();

  static late final Logger _logger;

  static void initialize() {
    _logger = Logger(
      filter: _AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none,
      ),
    );
  }

  static void d(dynamic message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _logger.d(_formatMessage(message, tag), error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _logger.i(_formatMessage(message, tag), error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _logger.w(_formatMessage(message, tag), error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _logger.e(_formatMessage(message, tag), error: error, stackTrace: stackTrace);
  }

  static void f(dynamic message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _logger.f(_formatMessage(message, tag), error: error, stackTrace: stackTrace);
  }

  static String _formatMessage(dynamic message, String? tag) {
    if (tag != null) {
      return '[$tag] $message';
    }
    return message.toString();
  }
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!EnvConfig.enableLogging) {
      // In production, only log warnings, errors, and fatals
      return event.level.value >= Level.warning.value;
    }
    return true; // Log everything in dev/staging
  }
}
