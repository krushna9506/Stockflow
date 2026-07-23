import 'package:dio/dio.dart';
import '../../services/logger_service.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LoggerService.d(
      'REQ: ${options.method} ${options.uri}\nHeaders: ${options.headers}\nData: ${options.data}',
      tag: 'API',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LoggerService.d(
      'RES: ${response.statusCode} ${response.requestOptions.uri}\nData: ${response.data}',
      tag: 'API',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggerService.e(
      'ERR: ${err.response?.statusCode} ${err.requestOptions.uri}\nMessage: ${err.message}',
      error: err,
      tag: 'API',
    );
    super.onError(err, handler);
  }
}
