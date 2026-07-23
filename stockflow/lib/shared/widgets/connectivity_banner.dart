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
    Color borderColor;
    Color dotColor;
    Color textColor;
    String label;

    switch (status) {
      case ConnectivityStatus.online:
        bgColor = const Color(0xFFE6F4EA);
        borderColor = const Color(0xFFCEEAD6);
        dotColor = const Color(0xFF137333);
        textColor = const Color(0xFF137333);
        label = 'ONLINE';
        break;
      case ConnectivityStatus.offline:
        bgColor = const Color(0xFFFCE8E6);
        borderColor = const Color(0xFFFAD2CF);
        dotColor = const Color(0xFFC5221F);
        textColor = const Color(0xFFC5221F);
        label = 'OFFLINE';
        break;
      case ConnectivityStatus.syncing:
        bgColor = const Color(0xFFE8F0FE);
        borderColor = const Color(0xFFD2E3FC);
        dotColor = const Color(0xFF1A73E8);
        textColor = const Color(0xFF1A73E8);
        label = 'SYNCING';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
