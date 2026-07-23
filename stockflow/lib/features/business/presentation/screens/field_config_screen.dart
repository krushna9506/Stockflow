import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/business_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_provider.dart';
import 'package:drift/drift.dart' show Value;

class FieldConfigScreen extends ConsumerStatefulWidget {
  const FieldConfigScreen({super.key});

  @override
  ConsumerState<FieldConfigScreen> createState() => _FieldConfigScreenState();
}

class _FieldConfigScreenState extends ConsumerState<FieldConfigScreen> {
  Set<String> _enabledKeys = {};
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _init();
      _initialized = true;
    }
  }

  Future<void> _init() async {
    final repo = ref.read(businessRepositoryProvider);
    final business = await repo.getActiveBusiness();
    if (business != null) {
      final defaults =
          AppConstants.defaultFieldsByType[business.businessType] ?? [];
      setState(() => _enabledKeys = Set.from(defaults));
    }
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isLoading = true);
    try {
      final businessId = ref.read(activeBusinessIdProvider);
      final db = ref.read(appDatabaseProvider);

      // Save enabled custom fields
      int order = 0;
      for (final field in AppConstants.availableFields) {
        final key = field['key']!;
        final isEnabled = _enabledKeys.contains(key);

        // Check if field already exists
        final existing = await db.customFieldDao.getAllFields(businessId);
        final existingField = existing
            .cast<CustomField?>()
            .firstWhere((f) => f?.fieldKey == key, orElse: () => null);

        if (existingField != null) {
          await db.customFieldDao.updateField(
            existingField
                .toCompanion(true)
                .copyWith(isEnabled: Value(isEnabled)),
          );
        } else {
          await db.customFieldDao.insertField(
            CustomFieldsCompanion.insert(
              businessId: businessId,
              fieldKey: key,
              fieldLabel: field['label']!,
              fieldType: Value(field['type']!),
              isEnabled: Value(isEnabled),
              sortOrder: Value(order),
            ),
          );
        }
        order++;
      }

      // Mark setup complete
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(AppConstants.keyBusinessSetupDone, true);

      if (mounted) context.go('/sell');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Fields'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepRow(current: 3, total: 3),
                const SizedBox(height: 20),
                Text('Configure Product Fields',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Choose which fields appear when adding products',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: AppConstants.availableFields.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final field = AppConstants.availableFields[i];
                final key = field['key']!;
                final enabled = _enabledKeys.contains(key);

                return SwitchListTile.adaptive(
                  value: enabled,
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        _enabledKeys.add(key);
                      } else {
                        _enabledKeys.remove(key);
                      }
                    });
                  },
                  title: Text(field['label']!),
                  subtitle: Text(
                    field['type']!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  secondary: Icon(
                    _fieldIcon(key),
                    color: enabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                  activeTrackColor: cs.primary,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Get Started',
                icon: Icons.check,
                onPressed: _saveAndFinish,
                isLoading: _isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fieldIcon(String key) {
    switch (key) {
      case 'brand':
        return Icons.branding_watermark_outlined;
      case 'barcode':
        return Icons.qr_code_outlined;
      case 'expiryDate':
        return Icons.event_outlined;
      case 'warranty':
        return Icons.verified_outlined;
      case 'batchNumber':
        return Icons.tag_outlined;
      case 'serialNumber':
        return Icons.pin_outlined;
      case 'modelNumber':
        return Icons.model_training_outlined;
      case 'manufacturer':
        return Icons.factory_outlined;
      case 'storageLocation':
        return Icons.location_on_outlined;
      case 'supplier':
        return Icons.local_shipping_outlined;
      case 'notes':
        return Icons.notes_outlined;
      default:
        return Icons.label_outline;
    }
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
