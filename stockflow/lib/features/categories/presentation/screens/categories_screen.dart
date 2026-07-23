import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/category_repository.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;
import '../../../stock/presentation/providers/stock_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessId = ref.watch(activeBusinessIdProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (cats) {
          if (cats.isEmpty) {
            return sw.EmptyWidget(
              message: 'No categories yet',
              subMessage: 'Tap + to add a category',
              icon: Icons.category_outlined,
              action: () => _showAddDialog(context, ref, businessId),
              actionLabel: 'Add Category',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _CategoryCard(category: cats[i], businessId: businessId),
          );
        },
        loading: () =>
            const sw.LoadingWidget(message: 'Loading categories...'),
        error: (e, _) => sw.ErrorWidget(message: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref, businessId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, int businessId) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _CategoryDialog(businessId: businessId),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard(
      {required this.category, required this.businessId});
  final Category category;
  final int businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppTheme.hexToColor(category.color);
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _iconFromName(category.icon),
            color: color,
          ),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: category.description != null
            ? Text(category.description!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _CategoryDialog(
                  businessId: businessId,
                  existing: category,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () => _confirmDelete(context, ref, category.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
            'Products in this category will have no category assigned.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).deleteCategory(id);
    }
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'grocery':
        return Icons.shopping_basket_outlined;
      case 'electronics':
        return Icons.electrical_services_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({required this.businessId, this.existing});
  final int businessId;
  final Category? existing;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Color _selectedColor = AppTheme.categoryColors.first;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
      _selectedColor = AppTheme.hexToColor(widget.existing!.color);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final colorHex = AppTheme.colorToHex(_selectedColor);

      if (_isEdit) {
        await repo.updateCategory(widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          color: colorHex,
          description: Value(_descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim()),
        ));
      } else {
        await repo.addCategory(
          businessId: widget.businessId,
          name: _nameCtrl.text.trim(),
          color: colorHex,
          icon: 'category',
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Category' : 'Add Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Color',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppTheme.categoryColors.map((c) {
                  final selected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
