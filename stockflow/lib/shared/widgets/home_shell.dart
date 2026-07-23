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
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectivityBanner(),
          NavigationBar(
            selectedIndex: selectedIndex,
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
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'POS / Billing',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Stock & Items',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Smart Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Profile & Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
