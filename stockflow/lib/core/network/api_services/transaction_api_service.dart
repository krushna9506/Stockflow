import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';

final transactionApiServiceProvider = Provider<TransactionApiService>((ref) {
  return TransactionApiService(ref.watch(apiClientProvider));
});

class TransactionApiService {
  TransactionApiService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getTransactions(int businessId, {int limit = 50, int offset = 0}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.transactions,
      queryParameters: {
        'business_id': businessId,
        'limit': limit,
        'offset': offset,
      },
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.transactions,
      data: data,
    );
    return response.data;
  }
}
