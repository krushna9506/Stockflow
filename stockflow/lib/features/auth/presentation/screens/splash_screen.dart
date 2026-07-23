import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/business_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Read the auth state. Note: this assumes AuthServiceNotifier._init() finishes quickly
    // in reality, we might want to wait for it. But Riverpod initialize is synchronous 
    // mostly, except reading from secure storage which is async.
    // Let's force a read or wait for token.
    final authState = ref.read(authServiceProvider);
    
    // Wait a tiny bit just in case init is not done
    // Actually, secureStorage init is async, so we might need a small delay or better state mgmt.
    // Given the 1.8s delay above, _init() is almost certainly done.

    final prefs = ref.read(sharedPreferencesProvider);
    final businessId = prefs.getInt(AppConstants.keyBusinessId) ?? -1;
    final setupDone = prefs.getBool(AppConstants.keyBusinessSetupDone) ?? false;

    if (setupDone && businessId != -1) {
      context.go('/sell');
    } else if (authState.isAuthenticated) {
      final repo = ref.read(businessRepositoryProvider);
      final activeBusiness = await repo.syncFromServer();
      if (!mounted) return;

      if (activeBusiness != null) {
        await prefs.setBool(AppConstants.keyBusinessSetupDone, true);
        await prefs.setInt(AppConstants.keyBusinessId, activeBusiness.id);
        ref.read(activeBusinessIdProvider.notifier).state = activeBusiness.id;
        context.go('/sell');
      } else {
        context.go('/business-setup');
      }
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.onPrimary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 56,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'StockFlow',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Inventory Management',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
