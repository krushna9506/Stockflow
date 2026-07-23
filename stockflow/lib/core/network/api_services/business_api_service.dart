import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';

final businessApiServiceProvider = Provider<BusinessApiService>((ref) {
  return BusinessApiService(ref.watch(apiClientProvider));
});

class BusinessApiService {
  BusinessApiService(this._apiClient);
  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getBusinesses() async {
    final response = await _apiClient.dio.get(ApiEndpoints.businesses);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createBusiness(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.businesses,
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateBusiness(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '${ApiEndpoints.businesses}/$id',
      data: data,
    );
    return response.data;
  }
}
