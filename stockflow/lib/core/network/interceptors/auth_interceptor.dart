import 'package:dio/dio.dart';
import '../../services/secure_storage_service.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
    required this.onLogout,
  });

  final SecureStorageService secureStorage;
  final Dio dio;
  final Function() onLogout;
  
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Exclude auth endpoints from getting a bearer token
    if (options.path.contains(ApiEndpoints.login) || 
        options.path.contains(ApiEndpoints.register) || 
        options.path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(options);
    }

    final accessToken = await secureStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Don't intercept 401s from the refresh endpoint itself
      if (err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
        onLogout();
        return handler.next(err);
      }

      // If already refreshing, queue this request
      if (_isRefreshing) {
        // We use a Completer to pause the request until refresh is done
        // For simplicity in this implementation, we just reject if already refreshing
        return handler.next(err);
      }

      _isRefreshing = true;

      try {
        final refreshToken = await secureStorage.getRefreshToken();
        if (refreshToken == null) {
          onLogout();
          return handler.next(err);
        }

        // Attempt refresh
        final response = await dio.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': refreshToken},
          options: Options(
            headers: {'Authorization': 'Bearer $refreshToken'},
          )
        );

        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await secureStorage.saveTokens(
          accessToken: newAccessToken, 
          refreshToken: newRefreshToken ?? refreshToken
        );

        // Retry original request
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';
        final cloneReq = await dio.fetch(options);
        
        return handler.resolve(cloneReq);
      } catch (e) {
        onLogout();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }
    
    return handler.next(err);
  }
}
