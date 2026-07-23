import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'secure_storage_service.dart';
import 'logger_service.dart';

final authServiceProvider = StateNotifierProvider<AuthServiceNotifier, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  // We don't watch apiClientProvider directly to avoid circular dependency since
  // ApiClient uses authServiceProvider for the onLogout callback. 
  // We'll read it when we need it.
  return AuthServiceNotifier(secureStorage: secureStorage, ref: ref);
});

class AuthState {
  const AuthState({this.isAuthenticated = false, this.isLoading = false});
  final bool isAuthenticated;
  final bool isLoading;
}

class AuthServiceNotifier extends StateNotifier<AuthState> {
  AuthServiceNotifier({
    required this.secureStorage,
    required this.ref,
  }) : super(const AuthState()) {
    _init();
  }

  final SecureStorageService secureStorage;
  final Ref ref;

  Future<void> _init() async {
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      state = const AuthState(isAuthenticated: true);
    }
  }

  Dio get _dio => ref.read(apiClientProvider).dio;

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      final userId = response.data['user_id']?.toString() ?? 'unknown';

      await secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await secureStorage.saveUserId(userId);

      state = const AuthState(isAuthenticated: true, isLoading: false);
      LoggerService.i('Login successful', tag: 'AUTH');
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      await _dio.post(ApiEndpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
      });

      state = const AuthState(isAuthenticated: false, isLoading: false);
      LoggerService.i('OTP sent for registration', tag: 'AUTH');
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String otp) async {
    state = const AuthState(isLoading: true);
    try {
      final response = await _dio.post(ApiEndpoints.verifyEmail, data: {
        'email': email,
        'otp': otp,
      });

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      final userId = response.data['user_id']?.toString() ?? 'unknown';

      await secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await secureStorage.saveUserId(userId);

      state = const AuthState(isAuthenticated: true, isLoading: false);
      LoggerService.i('Email verified and logged in', tag: 'AUTH');
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AuthState(isLoading: true);
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    state = const AuthState(isLoading: true);
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await secureStorage.clearAll();
    state = const AuthState(isAuthenticated: false, isLoading: false);
    LoggerService.i('Logged out', tag: 'AUTH');
  }
}
