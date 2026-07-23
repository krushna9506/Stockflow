import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/business_repository.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/update_dialog.dart';
import '../../../../shared/widgets/developer_license_dialog.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authServiceProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (!mounted) return;

      final repo = ref.read(businessRepositoryProvider);
      // Sync cloud business & data for this account
      final activeBusiness = await repo.syncFromServer();
      final prefs = ref.read(sharedPreferencesProvider);
      
      if (!mounted) return;

      if (activeBusiness != null) {
        // Business already exists for this account on cloud or local, skip setup
        await prefs.setBool(AppConstants.keyBusinessSetupDone, true);
        await prefs.setInt(AppConstants.keyBusinessId, activeBusiness.id);
        
        if (!mounted) return;
        
        ref.read(activeBusinessIdProvider.notifier).state = activeBusiness.id;
        context.go('/sell');
      } else {
        // Brand new account with no business anywhere, proceed to setup
        context.go('/business-setup');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        // ErrorHandler handles mapping to AppException and showing SnackBar
        // But since we use global ErrorHandler in main, it will catch uncaught. 
        // Wait, we caught it here, so we must call ErrorHandler manually.
        ErrorHandler.handle(e, stackTrace);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.lock_outline,
                  size: 64, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your inventory across devices',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    AppValidators.required(v, 'Email') ??
                    AppValidators.email(v),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passCtrl,
                label: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                obscureText: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) => AppValidators.minLength(v, 6, 'Password'),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign In',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/business-setup'),
                child: const Text('Continue Offline'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final notification = ref.read(notificationServiceProvider);
                    notification.showInfo('Checking for app updates...');
                    final updateInfo = await ref.read(updateServiceProvider).checkForUpdates();
                    if (context.mounted) {
                      if (updateInfo.isUpdateAvailable) {
                        showUpdateDialogIfAvailable(context, updateInfo);
                      } else {
                        notification.showInfo('Your app is up to date.');
                      }
                    }
                  },
                  icon: const Icon(Icons.system_update_outlined, size: 16),
                  label: const Text(
                    'Check for App Updates',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () => showDeveloperLicenseDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'StockFlow v1.1.0 • Licensed Software',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Developed & Powered by Krushna Donge',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
