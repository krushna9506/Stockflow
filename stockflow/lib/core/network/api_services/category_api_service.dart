import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';

final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  return CategoryApiService(ref.watch(apiClientProvider));
});

class CategoryApiService {
  CategoryApiService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getCategories(int businessId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.categories,
      queryParameters: {'business_id': businessId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.categories,
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.categories}/$id',
      data: data,
    );
    return response.data;
  }

  Future<void> deleteCategory(int id) async {
    await _apiClient.dio.delete('${ApiEndpoints.categories}/$id');
  }
}
