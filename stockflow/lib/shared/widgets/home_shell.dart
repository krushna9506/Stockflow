import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'connectivity_banner.dart';
import '../../core/services/sync_manager.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/stock')) return 1;
    if (location.startsWith('/dashboard')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // /sell (POS / Billing) is tab 0
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);

    // Initialize SyncManager
    ref.watch(syncManagerProvider);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 12, bottom: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: const ConnectivityBanner(),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        height: 62,
        labelBehavior: NavigationBarLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/sell');
              break;
            case 1:
              context.go('/stock');
              break;
            case 2:
              context.go('/dashboard');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined, size: 22),
            selectedIcon: Icon(Icons.point_of_sale, size: 22),
            label: 'POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, size: 22),
            selectedIcon: Icon(Icons.inventory_2, size: 22),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, size: 22),
            selectedIcon: Icon(Icons.analytics, size: 22),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 22),
            selectedIcon: Icon(Icons.settings, size: 22),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
