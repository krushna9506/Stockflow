import 'package:flutter/foundation.dart';

/// Environment configuration for StockFlow.
///
/// Set via `--dart-define=ENV=production` at build time.
/// Defaults to `development` if not specified.
enum Environment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static late final Environment _env;
  static late final String _baseUrl;

  /// Call once during app startup.
  static void initialize() {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'development');
    _env = Environment.values.firstWhere(
      (e) => e.name == envStr,
      orElse: () => Environment.development,
    );
    
    // Check for user-defined BASE_URL
    const customBaseUrl = String.fromEnvironment('BASE_URL');
    
    if (customBaseUrl.isNotEmpty) {
      _baseUrl = customBaseUrl;
    } else {
      // Default local URLs based on platform (since Android emulator requires 10.0.2.2 to reach host)
      // Note: For physical devices, you must pass --dart-define=BASE_URL=http://<YOUR_LOCAL_IP>:8000/api/v1
      bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      
      _baseUrl = 'https://stockflow-backend-75yu.onrender.com/api/v1';
    }
  }

  static Environment get environment => _env;
  static String get baseUrl => _baseUrl;
  static bool get isDevelopment => _env == Environment.development;
  static bool get isProduction => _env == Environment.production;

  /// API timeouts
  static Duration get connectTimeout => const Duration(seconds: 15);
  static Duration get receiveTimeout => const Duration(seconds: 30);
  static Duration get sendTimeout => const Duration(seconds: 30);

  /// Feature flags
  static bool get enableLogging => !isProduction;
  static bool get enableApiLogging => isDevelopment;

  /// App update check interval
  static Duration get updateCheckInterval => const Duration(hours: 6);
}
