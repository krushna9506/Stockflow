import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'logger_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.watch(apiClientProvider));
});

class UpdateInfo {
  UpdateInfo({
    required this.isUpdateAvailable,
    this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.isMandatory = false,
  });

  final bool isUpdateAvailable;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final bool isMandatory;
}

class UpdateService {
  UpdateService(this._apiClient);
  final ApiClient _apiClient;

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _apiClient.dio.get(
        ApiEndpoints.updateCheck,
        queryParameters: {
          'platform': 'android', // or dynamically determine platform
          'current_version': currentVersion,
        },
      );

      final data = response.data;
      final bool isAvailable = data['update_available'] ?? false;

      return UpdateInfo(
        isUpdateAvailable: isAvailable,
        latestVersion: data['latest_version'],
        downloadUrl: data['download_url'],
        releaseNotes: data['release_notes'],
        isMandatory: data['mandatory'] ?? false,
      );
    } catch (e) {
      LoggerService.e('Failed to check for updates', error: e, tag: 'UPDATE');
      return UpdateInfo(isUpdateAvailable: false);
    }
  }
}
