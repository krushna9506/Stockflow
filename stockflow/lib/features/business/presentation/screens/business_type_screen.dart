import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../repositories/business_repository.dart';
import '../../../../shared/widgets/app_button.dart';

class BusinessTypeScreen extends ConsumerStatefulWidget {
  const BusinessTypeScreen({super.key});

  @override
  ConsumerState<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends ConsumerState<BusinessTypeScreen> {
  String? _selectedType;
  bool _isLoading = false;

  static const _typeIcons = {
    'Grocery': Icons.shopping_basket_outlined,
    'Hardware': Icons.build_outlined,
    'Electronics': Icons.electrical_services_outlined,
    'Medical': Icons.medical_services_outlined,
    'Garments': Icons.checkroom_outlined,
    'Automobile': Icons.directions_car_outlined,
    'Furniture': Icons.chair_outlined,
    'General': Icons.storefront_outlined,
    'Custom': Icons.tune_outlined,
  };

  Future<void> _continue() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business type')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(businessRepositoryProvider);
      final business = await repo.getActiveBusiness();
      if (business != null) {
        await repo.updateBusiness(
          business.copyWith(businessType: _selectedType!),
        );
      }

      if (mounted) context.go('/field-config');
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
        title: const Text('Business Type'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepRow(current: 2, total: 3),
                const SizedBox(height: 20),
                Text('What type of business?',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'This sets the default product fields for your store',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
              children: AppConstants.businessTypes.map((type) {
                final isSelected = _selectedType == type;
                final icon = _typeIcons[type] ?? Icons.category_outlined;
                final colorIndex =
                    AppConstants.businessTypes.indexOf(type) %
                        AppTheme.categoryColors.length;
                final color = AppTheme.categoryColors[colorIndex];

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.15)
                                : color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon,
                              size: 28,
                              color: isSelected ? cs.primary : color),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          type,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? cs.primary
                                    : cs.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _continue,
                isLoading: _isLoading,
              ),
            ),
          ),
        ],
      ),
    );
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
