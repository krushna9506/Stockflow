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
        bgColor = Colors.green.shade800;
        textColor = Colors.white;
        message = 'Cloud Connected';
        icon = Icons.cloud_done;
        break;
      case ConnectivityStatus.offline:
        bgColor = Colors.amber.shade900;
        textColor = Colors.white;
        message = 'Offline Mode';
        icon = Icons.cloud_off;
        break;
      case ConnectivityStatus.syncing:
        bgColor = cs.primary;
        textColor = cs.onPrimary;
        message = 'Syncing (${syncProgress.syncedItems}/${syncProgress.totalItems})';
        icon = Icons.sync;
        showProgress = true;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              else
                Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
