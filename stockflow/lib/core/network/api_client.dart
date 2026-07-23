import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(
    secureStorage: secureStorage,
    onLogout: () {
      // In a real app we'd dispatch a logout action
      // For now, we rely on the auth_service
      ref.read(authServiceProvider.notifier).logout();
    },
  );
});

class ApiClient {
  ApiClient({
    required this.secureStorage,
    required this.onLogout,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        sendTimeout: EnvConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        dio: _dio, // Need to be careful of circular dependency here in real implementation, but for refresh we can reuse the instance or create a dedicated one
        onLogout: onLogout,
      ),
      RetryInterceptor(dio: _dio),
      ErrorInterceptor(),
      if (EnvConfig.enableApiLogging) LoggingInterceptor(),
    ]);
  }

  late final Dio _dio;
  final SecureStorageService secureStorage;
  final Function() onLogout;

  Dio get dio => _dio;
}
