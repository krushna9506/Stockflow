import 'package:flutter/material.dart';
import '../../../../core/widgets/local_image_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/validators.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/stock_providers.dart';
import 'package:drift/drift.dart' show Value;

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.editProduct});
  final Product? editProduct;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '0');
  final _skuCtrl = TextEditingController();

  // Dynamic attribute controllers
  final Map<String, TextEditingController> _attrControllers = {};

  int? _selectedCategoryId;
  String? _imagePath;
  bool _isLoading = false;
  bool get _isEdit => widget.editProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _populateEdit();
    }
  }

  Future<void> _populateEdit() async {
    final p = widget.editProduct!;
    _nameCtrl.text = p.name;
    _purchaseCtrl.text = p.purchasePrice.toString();
    _sellCtrl.text = p.sellingPrice.toString();
    _qtyCtrl.text = p.currentQuantity.toString();
    _minStockCtrl.text = p.minimumStock.toString();
    _skuCtrl.text = p.sku ?? '';
    _selectedCategoryId = p.categoryId;
    _imagePath = p.imagePath;

    // Load existing attributes
    final attrs =
        await ref.read(productRepositoryProvider).getProductAttributes(p.id);
    for (final a in attrs) {
      _attrControllers[a.fieldKey] = TextEditingController(
        text: a.fieldValue ?? '',
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellCtrl.dispose();
    _qtyCtrl.dispose();
    _minStockCtrl.dispose();
    _skuCtrl.dispose();
    for (final c in _attrControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final businessId = ref.read(activeBusinessIdProvider);
      final repo = ref.read(productRepositoryProvider);

      // Build attribute map
      final attributes = <String, String>{};
      for (final e in _attrControllers.entries) {
        if (e.value.text.isNotEmpty) attributes[e.key] = e.value.text.trim();
      }

      if (_isEdit) {
        final updated = widget.editProduct!.copyWith(
          name: _nameCtrl.text.trim(),
          categoryId: Value(_selectedCategoryId),
          purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
          sellingPrice: double.tryParse(_sellCtrl.text) ?? 0,
          minimumStock: int.tryParse(_minStockCtrl.text) ?? 0,
          imagePath: Value(_imagePath),
          sku: Value(_skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim()),
        );
        await repo.updateProduct(product: updated, attributes: attributes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated!')),
          );
          context.pop();
        }
      } else {
        await repo.addProduct(
          businessId: businessId,
          name: _nameCtrl.text.trim(),
          categoryId: _selectedCategoryId,
          purchasePrice: double.tryParse(_purchaseCtrl.text) ?? 0,
          sellingPrice: double.tryParse(_sellCtrl.text) ?? 0,
          initialQuantity: int.tryParse(_qtyCtrl.text) ?? 0,
          minimumStock: int.tryParse(_minStockCtrl.text) ?? 0,
          imagePath: _imagePath,
          sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
          attributes: attributes,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added!')),
          );
          ref.invalidate(filteredProductsProvider);
          context.pop();
        }
      }
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final customFieldsAsync = ref.watch(enabledCustomFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: LocalImageRenderer(
                              imagePath: _imagePath!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 30, color: cs.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text('Add Photo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: cs.onSurfaceVariant)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Core Fields ──────────────────────────────────────────────
              _SectionLabel('Product Information'),
              const SizedBox(height: 12),
              AppTextField(
                controller: _nameCtrl,
                label: 'Product Name *',
                prefixIcon: const Icon(Icons.label_outlined),
                validator: (v) => AppValidators.required(v, 'Product name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Category picker
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Category')),
                    ...cats.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _skuCtrl,
                label: 'SKU / Code',
                prefixIcon: const Icon(Icons.pin_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),

              _SectionLabel('Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _purchaseCtrl,
                      label: 'Purchase Price *',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          AppValidators.required(v, 'Purchase price') ??
                          AppValidators.positiveNumber(v),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _sellCtrl,
                      label: 'Selling Price *',
                      prefixIcon: const Icon(Icons.sell_outlined),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          AppValidators.required(v, 'Selling price') ??
                          AppValidators.positiveNumber(v),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel('Stock'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _qtyCtrl,
                      label: _isEdit ? 'Current Qty' : 'Opening Qty',
                      prefixIcon: const Icon(Icons.inventory_outlined),
                      keyboardType: TextInputType.number,
                      validator: AppValidators.positiveInteger,
                      enabled: !_isEdit,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _minStockCtrl,
                      label: 'Min Stock',
                      prefixIcon: const Icon(Icons.warning_amber_outlined),
                      keyboardType: TextInputType.number,
                      validator: AppValidators.positiveInteger,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),

              // ── Dynamic Fields ──────────────────────────────────────────────
              customFieldsAsync.when(
                data: (fields) {
                  if (fields.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _SectionLabel('Additional Details'),
                      const SizedBox(height: 12),
                      ...fields.map((field) {
                        _attrControllers.putIfAbsent(
                            field.fieldKey, () => TextEditingController());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AppTextField(
                            controller: _attrControllers[field.fieldKey]!,
                            label: field.fieldLabel,
                            keyboardType: field.fieldType == 'number'
                                ? TextInputType.number
                                : TextInputType.text,
                            textInputAction: TextInputAction.next,
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isEdit ? 'Update Product' : 'Add Product',
                  icon: _isEdit ? Icons.save_outlined : Icons.add,
                  onPressed: _save,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
