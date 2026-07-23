import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/sync_service.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    final syncProgress = ref.watch(syncProgressProvider);

    final cs = Theme.of(context).colorScheme;
    Color bgColor;
    Color textColor;
    String message;
    IconData icon;
    bool showProgress = false;

    switch (status) {
      case ConnectivityStatus.online:
        bgColor = Colors.green.shade700;
        textColor = Colors.white;
        message = '🟢 Cloud Connected • Live Sync Active';
        icon = Icons.cloud_done_outlined;
        break;
      case ConnectivityStatus.offline:
        bgColor = cs.errorContainer;
        textColor = cs.onErrorContainer;
        message = '🔴 Offline Mode • Changes saved locally on device';
        icon = Icons.cloud_off_outlined;
        break;
      case ConnectivityStatus.syncing:
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        message = '🔄 Syncing with Cloud... (${syncProgress.syncedItems}/${syncProgress.totalItems})';
        icon = Icons.sync;
        showProgress = true;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showProgress)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            else
              Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
