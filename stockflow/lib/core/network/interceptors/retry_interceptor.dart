import 'dart:async';
import 'package:dio/dio.dart';
import '../../services/logger_service.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  });

  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final int retryCount = extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      LoggerService.w(
        'Retrying request ${err.requestOptions.uri} (Attempt ${retryCount + 1})',
        tag: 'API',
      );

      final delay = retryCount < retryDelays.length
          ? retryDelays[retryCount]
          : retryDelays.last;

      await Future.delayed(delay);

      try {
        final options = err.requestOptions;
        options.extra['retryCount'] = retryCount + 1;
        
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return super.onError(e, handler);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      // Retry on server errors (5xx)
      return statusCode >= 500 && statusCode < 600;
    }

    return false;
  }
}
