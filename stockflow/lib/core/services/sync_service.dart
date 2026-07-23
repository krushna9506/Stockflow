import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'logger_service.dart';
import 'connectivity_service.dart';

final syncProgressProvider = StateProvider<SyncProgress>((ref) => const SyncProgress());

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return SyncService(db: db, apiClient: apiClient, ref: ref);
});

class SyncProgress {
  const SyncProgress({
    this.totalItems = 0,
    this.syncedItems = 0,
    this.isSyncing = false,
  });
  final int totalItems;
  final int syncedItems;
  final bool isSyncing;
}

class SyncService {
  SyncService({
    required this.db,
    required this.apiClient,
    required this.ref,
  });

  final AppDatabase db;
  final ApiClient apiClient;
  final Ref ref;

  bool _isSyncing = false;

  Future<void> syncAll() async {
    if (_isSyncing) return;
    
    final pendingItems = await db.getPendingSyncItems();
    if (pendingItems.isEmpty) return;

    _isSyncing = true;
    ref.read(connectivityProvider.notifier).setSyncing(true);
    ref.read(syncProgressProvider.notifier).state = SyncProgress(
      totalItems: pendingItems.length,
      syncedItems: 0,
      isSyncing: true,
    );

    LoggerService.i('Starting sync for ${pendingItems.length} items', tag: 'SYNC');

    int successCount = 0;

    for (final item in pendingItems) {
      try {
        await _syncItem(item);
        await db.markSynced(item.id);
        successCount++;
        
        ref.read(syncProgressProvider.notifier).update((state) => 
          SyncProgress(
            totalItems: state.totalItems,
            syncedItems: successCount,
            isSyncing: true,
          )
        );
      } catch (e, stack) {
        LoggerService.e('Failed to sync item ${item.id}', error: e, stackTrace: stack, tag: 'SYNC');
        await db.incrementSyncRetry(item.id);
      }
    }

    _isSyncing = false;
    ref.read(connectivityProvider.notifier).setSyncing(false);
    ref.read(syncProgressProvider.notifier).state = const SyncProgress();

    LoggerService.i('Sync completed. Successfully synced $successCount/${pendingItems.length} items.', tag: 'SYNC');
  }

  Future<void> _syncItem(SyncQueueData item) async {
    final payloadMap = jsonDecode(item.payload) as Map<String, dynamic>;
    
    // Convert to a format the backend expects
    final requestData = {
      'entity_table': item.entityTable,
      'record_id': item.recordId,
      'operation': item.operation,
      'payload': payloadMap,
      'created_at': item.createdAt.toIso8601String(),
    };

    await apiClient.dio.post(
      ApiEndpoints.sync,
      data: requestData,
    );
  }
}
