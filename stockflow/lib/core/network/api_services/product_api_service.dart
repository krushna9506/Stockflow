import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';

final productApiServiceProvider = Provider<ProductApiService>((ref) {
  return ProductApiService(ref.watch(apiClientProvider));
});

class ProductApiService {
  ProductApiService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getProducts(int businessId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.products,
      queryParameters: {'business_id': businessId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.products,
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.products}/$id',
      data: data,
    );
    return response.data;
  }

  Future<void> deleteProduct(int id) async {
    await _apiClient.dio.delete('${ApiEndpoints.products}/$id');
  }
}
