import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/stock_providers.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final businessId = ref.read(activeBusinessIdProvider);
      await ref.read(productRepositoryProvider).stockIn(
            productId: widget.productId,
            businessId: businessId,
            quantity: int.parse(_qtyCtrl.text.trim()),
            unitPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0,
            supplier: _supplierCtrl.text.trim().isEmpty
                ? null
                : _supplierCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock added successfully!')),
        );
        ref.invalidate(productDetailProvider(widget.productId));
        context.pop();
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
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock In')),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          // Pre-fill purchase price
          if (_priceCtrl.text.isEmpty) {
            _priceCtrl.text = product.purchasePrice.toStringAsFixed(2);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                color: cs.onPrimaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                Text(
                                  'Current Stock: ${product.currentQuantity} units',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text('Stock In Details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _qtyCtrl,
                    label: 'Quantity *',
                    prefixIcon: const Icon(Icons.add_box_outlined),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _priceCtrl,
                    label: 'Purchase Price per Unit',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: AppValidators.positiveNumber,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _supplierCtrl,
                    label: 'Supplier (Optional)',
                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _notesCtrl,
                    label: 'Notes (Optional)',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Confirm Stock In',
                      icon: Icons.move_to_inbox,
                      onPressed: _save,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
