import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/local_image_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/update_service.dart';
import '../../../../providers/app_providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/update_dialog.dart';
import '../../../../shared/widgets/developer_license_dialog.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final businessAsync = ref.watch(activeBusinessStreamProvider);
    final business = businessAsync.valueOrNull;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Settings'),
      ),
      body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Business Card ──────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _BusinessAvatar(logoPath: business?.logoPath),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.name ?? 'My Business',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (business?.ownerName != null && business!.ownerName.isNotEmpty)
                            Text(
                              business.ownerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          if (business?.phone != null && business!.phone.isNotEmpty)
                            Text(
                              business.phone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          const SizedBox(height: 6),
                          Chip(
                            label: Text(business?.businessType ?? 'General'),
                            backgroundColor: cs.secondaryContainer,
                            labelStyle: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w600),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Business Details',
                      onPressed: () => context.go('/business-setup'),
                    ),
                  ],
                ),
              ),
            ),

              const SizedBox(height: 24),

              // ── Inventory Configuration ───────────────────────────────────
              _SectionHeader('Store & Inventory Setup'),
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories Management',
                subtitle: 'Organize items and customize category badges',
                onTap: () => context.push('/categories'),
              ),
              _SettingsTile(
                icon: Icons.tune_outlined,
                title: 'Product Field Configuration',
                subtitle: 'Customize fields for Brand, Size, Grade, Expiry & Barcodes',
                onTap: () => context.push('/field-config'),
              ),
              _SettingsTile(
                icon: Icons.receipt_long_outlined,
                title: 'Full Transaction Registry',
                subtitle: 'Audit all sales, returns, damages and adjustments',
                onTap: () => context.push('/transactions'),
              ),

              const SizedBox(height: 16),

              // ── App Settings ──────────────────────────────────────────────
              // ── System Settings ──────────────────────────────────────────────
              _SectionHeader('System Settings'),
              Card(
                child: SwitchListTile.adaptive(
                  secondary: Icon(Icons.dark_mode_outlined, color: cs.primary),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Toggle professional dark mode palette'),
                  value: isDark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  activeThumbColor: cs.primary,
                ),
              ),
              _SettingsTile(
                icon: Icons.system_update_outlined,
                title: 'Check for Updates',
                subtitle: 'Verify app version and install updates',
                onTap: () => _checkForUpdates(context, ref),
              ),

              const SizedBox(height: 16),

              // ── Data & Backup ──────────────────────────────────────────────
              _SectionHeader('Data & Security'),
              if (!kIsWeb) ...[
                _SettingsTile(
                  icon: Icons.restore_outlined,
                  title: 'Restore Database',
                  subtitle: 'Import existing data from backup file',
                  onTap: () => _restore(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.backup_outlined,
                  title: 'Export Backup (SQLite)',
                  subtitle: 'Create offline backup of products and records',
                  onTap: () => _backup(context, ref),
                ),
              ],

              // ── About & Licensing ──────────────────────────────────────────────
              _SectionHeader('About & Developer License'),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Software License & Credentials',
                subtitle: 'View Krushna Donge credentials, LinkedIn & Gmail',
                onTap: () => showDeveloperLicenseDialog(context),
              ),

              const SizedBox(height: 16),

              // ── Account ──────────────────────────────────────────────
              _SectionHeader('Session'),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Switch Business / Sign Out',
                subtitle: 'Exit active workspace session',
                onTap: () => _logout(context, ref),
                iconColor: cs.error,
              ),

              const SizedBox(height: 20),

              // Version & License Branding
              Center(
                child: InkWell(
                  onTap: () => showDeveloperLicenseDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              'StockFlow v1.1.0 • Licensed Software',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developed & Powered by Krushna Donge',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All Rights Reserved • Authorized Business Edition',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final updateInfo = await ref.read(updateServiceProvider).checkForUpdates();
    if (context.mounted) {
      if (updateInfo.isUpdateAvailable) {
        showUpdateDialogIfAvailable(context, updateInfo);
      } else {
        ref.read(notificationServiceProvider).showInfo('Your app is up to date.');
      }
    }
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final notification = ref.read(notificationServiceProvider);
    try {
      final backupPath = await ref.read(backupServiceProvider).exportToCsv(1);
      if (backupPath != null) {
        notification.showSuccess('Inventory CSV Excel backup saved to $backupPath');
      } else {
        notification.showError('Failed to create CSV Excel backup.');
      }
    } catch (e) {
      notification.showError('Backup error: $e');
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final notification = ref.read(notificationServiceProvider);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes != null) {
          final content = utf8.decode(fileBytes);
          final count = await ref.read(backupServiceProvider).importFromCsv(content, 1);
          if (count > 0) {
            notification.showSuccess('Successfully imported $count products from CSV Excel!');
            return;
          }
        }
        notification.showError('No valid products found in selected file.');
      }
    } catch (e) {
      notification.showError('Restore failed: $e');
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
            'Are you sure you want to sign out of your StockFlow account? You will need to sign in again to access cloud sync.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider.notifier).logout();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(AppConstants.keyBusinessId);
      await prefs.remove(AppConstants.keyBusinessSetupDone);
      ref.read(activeBusinessIdProvider.notifier).state = -1;
      if (context.mounted) {
        context.go('/welcome');
      }
    }
  }
}

class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({this.logoPath});
  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (logoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LocalImageRenderer(
          imagePath: logoPath!,
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.store, size: 32, color: cs.onPrimaryContainer),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? cs.onSurface),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
