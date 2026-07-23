import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'logger_service.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref: ref);
  ref.onDispose(manager.dispose);
  return manager;
});

class SyncManager {
  SyncManager({required this.ref}) {
    _init();
  }

  final Ref ref;
  ProviderSubscription<ConnectivityStatus>? _subscription;

  void _init() {
    // Listen to connectivity changes
    _subscription = ref.listen<ConnectivityStatus>(
      connectivityProvider,
      (previous, next) {
        if (previous == ConnectivityStatus.offline && next == ConnectivityStatus.online) {
          LoggerService.i('Network restored, triggering sync...', tag: 'SYNC_MANAGER');
          // Add a small delay to ensure connection is fully established
          Future.delayed(const Duration(seconds: 2), () {
            _triggerSync();
          });
        }
      },
    );
    
    // Also try to sync on startup if online
    if (ref.read(connectivityProvider.notifier).isOnline) {
      Future.delayed(const Duration(seconds: 5), _triggerSync);
    }
  }

  void _triggerSync() {
    ref.read(syncServiceProvider).syncAll();
  }

  void dispose() {
    _subscription?.close();
  }
}
