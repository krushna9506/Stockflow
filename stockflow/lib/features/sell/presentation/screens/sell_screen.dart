import 'package:flutter/material.dart';
import '../../../../core/widgets/local_image_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../stock/presentation/providers/stock_providers.dart';

enum StockFilterType { all, inStock, lowStock, outOfStock }

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  StockFilterType _stockFilter = StockFilterType.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showBillingModal(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _POSBillingSheet(product: product),
    );
  }

  void _showFilterSheet(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cs = Theme.of(ctx).colorScheme;
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filter Products', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Text('Stock Status', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All Items',
                        isSelected: _stockFilter == StockFilterType.all,
                        onSelected: () {
                          setState(() => _stockFilter = StockFilterType.all);
                          setSheetState(() {});
                        },
                      ),
                      _FilterChip(
                        label: 'In Stock',
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF10B981),
                        isSelected: _stockFilter == StockFilterType.inStock,
                        onSelected: () {
                          setState(() => _stockFilter = StockFilterType.inStock);
                          setSheetState(() {});
                        },
                      ),
                      _FilterChip(
                        label: 'Low Stock',
                        icon: Icons.warning_amber_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        isSelected: _stockFilter == StockFilterType.lowStock,
                        onSelected: () {
                          setState(() => _stockFilter = StockFilterType.lowStock);
                          setSheetState(() {});
                        },
                      ),
                      _FilterChip(
                        label: 'Out of Stock',
                        icon: Icons.remove_circle_outline,
                        iconColor: const Color(0xFFEF4444),
                        isSelected: _stockFilter == StockFilterType.outOfStock,
                        onSelected: () {
                          setState(() => _stockFilter = StockFilterType.outOfStock);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Categories', style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All Categories',
                          isSelected: _selectedCategoryId == null,
                          onSelected: () {
                            setState(() => _selectedCategoryId = null);
                            setSheetState(() {});
                          },
                        ),
                        ...categories.map((c) => _FilterChip(
                              label: c.name,
                              isSelected: _selectedCategoryId == c.id,
                              onSelected: () {
                                setState(() => _selectedCategoryId = c.id);
                                setSheetState(() {});
                              },
                            )),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Apply Filters',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS & Billing'),
        actions: [
          if (_searchQuery.isNotEmpty ||
              _selectedCategoryId != null ||
              _stockFilter != StockFilterType.all)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _searchQuery = '';
                  _selectedCategoryId = null;
                  _stockFilter = StockFilterType.all;
                });
              },
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Reset Filters'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // ── Smart Filter Section ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search products by name, SKU, barcode...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Button
                  Stack(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFilterSheet(categoriesAsync.valueOrNull ?? []),
                      ),
                      if (_stockFilter != StockFilterType.all || _selectedCategoryId != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cs.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Product List ──────────────────────────────────────────────
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  // Apply smart filters
                  final filtered = products.where((p) {
                    // Search query
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matchesName = p.name.toLowerCase().contains(q);
                      final matchesSku =
                          (p.sku ?? '').toLowerCase().contains(q);
                      if (!matchesName && !matchesSku) return false;
                    }
                    // Category filter
                    if (_selectedCategoryId != null &&
                        p.categoryId != _selectedCategoryId) {
                      return false;
                    }
                    // Stock status filter
                    switch (_stockFilter) {
                      case StockFilterType.inStock:
                        if (p.currentQuantity <= 0) return false;
                        break;
                      case StockFilterType.lowStock:
                        if (p.currentQuantity <= 0 ||
                            p.currentQuantity > p.minimumStock) {
                          return false;
                        }
                        break;
                      case StockFilterType.outOfStock:
                        if (p.currentQuantity > 0) return false;
                        break;
                      case StockFilterType.all:
                        break;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    if (products.isEmpty) {
                      return sw.EmptyWidget(
                        message: 'No items in inventory yet',
                        subMessage: 'Add products in Inventory tab to start billing',
                        icon: Icons.inventory_2_outlined,
                      );
                    }
                    return sw.EmptyWidget(
                      message: 'No products match filters',
                      subMessage: 'Try adjusting your search query or smart filters',
                      icon: Icons.filter_alt_off_outlined,
                      action: () {
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _selectedCategoryId = null;
                          _stockFilter = StockFilterType.all;
                        });
                      },
                      actionLabel: 'Clear All Filters',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final isOut = p.currentQuantity == 0;
                      final isLow = !isOut && p.currentQuantity <= p.minimumStock;

                      return Card(
                        child: InkWell(
                          onTap: () => _showBillingModal(p),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                _ProductThumb(imagePath: p.imagePath, isOut: isOut),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                      ),
                                      if (p.sku != null && p.sku!.isNotEmpty)
                                        Text(
                                          'SKU: ${p.sku}',
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isOut
                                                  ? cs.errorContainer
                                                  : isLow
                                                      ? const Color(0xFFFEF3C7)
                                                      : cs.primaryContainer.withValues(alpha: 0.6),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isOut
                                                      ? Icons.remove_circle_outline
                                                      : isLow
                                                          ? Icons.warning_amber_outlined
                                                          : Icons.inventory_2_outlined,
                                                  size: 14,
                                                  color: isOut
                                                      ? cs.onErrorContainer
                                                      : isLow
                                                          ? const Color(0xFFD97706)
                                                          : cs.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isOut
                                                      ? 'Out of Stock'
                                                      : '${p.currentQuantity} in stock',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isOut
                                                        ? cs.onErrorContainer
                                                        : isLow
                                                            ? const Color(0xFFD97706)
                                                            : cs.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.formatCurrency(p.sellingPrice),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    FilledButton.icon(
                                      onPressed: () => _showBillingModal(p),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 0),
                                        minimumSize: const Size(80, 34),
                                      ),
                                      icon: const Icon(Icons.point_of_sale, size: 16),
                                      label: const Text('Bill Item'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const sw.LoadingWidget(message: 'Loading inventory catalog...'),
                error: (e, _) => sw.ErrorWidget(message: e.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? cs.onPrimary : (iconColor ?? cs.primary))
          : null,
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imagePath, required this.isOut});
  final String? imagePath;
  final bool isOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isOut
            ? cs.errorContainer.withValues(alpha: 0.4)
            : cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null && imagePath!.isNotEmpty
          ? LocalImageRenderer(imagePath: imagePath!, fit: BoxFit.cover)
          : Icon(
              Icons.inventory_2,
              color: isOut ? cs.error : cs.primary,
              size: 26,
            ),
    );
  }
}

class _POSBillingSheet extends ConsumerStatefulWidget {
  const _POSBillingSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_POSBillingSheet> createState() => _POSBillingSheetState();
}

class _POSBillingSheetState extends ConsumerState<_POSBillingSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  final _customerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  int get _quantity => int.tryParse(_qtyCtrl.text.trim()) ?? 1;
  double get _unitPrice =>
      double.tryParse(_priceCtrl.text.trim()) ?? widget.product.sellingPrice;
  double get _totalAmount => _quantity * _unitPrice;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _priceCtrl = TextEditingController(
      text: widget.product.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _customerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _adjustQty(int delta) {
    final current = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final next = (current + delta).clamp(1, 9999);
    setState(() {
      _qtyCtrl.text = next.toString();
    });
  }

  Future<void> _completeBilling() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quantity > widget.product.currentQuantity && widget.product.currentQuantity > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Low Stock Warning'),
          content: Text(
              'Only ${widget.product.currentQuantity} units available in stock. Do you want to bill $_quantity units anyway?'),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => ctx.pop(true), child: const Text('Proceed & Bill')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final businessId = ref.read(activeBusinessIdProvider);
      await ref.read(productRepositoryProvider).sell(
            productId: widget.product.id,
            businessId: businessId,
            quantity: _quantity,
            unitPrice: _unitPrice,
            customer: _customerCtrl.text.trim().isEmpty
                ? null
                : _customerCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      if (mounted) {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentTransactionsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'POS Bill Completed: Sold $_quantity × ${widget.product.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing sale: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle pill & title row
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick POS Checkout',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product summary card inside modal
              Card(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.inventory_2, color: cs.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            Text(
                              'Available Stock: ${widget.product.currentQuantity} units',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(widget.product.sellingPrice),
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quantity Stepper & Price
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity *',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => _adjustQty(-1),
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AppTextField(
                                controller: _qtyCtrl,
                                label: '',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    AppValidators.positiveInteger(v),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              onPressed: () => _adjustQty(1),
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price per Unit (₹)',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _priceCtrl,
                          label: '',
                          prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: AppValidators.positiveNumber,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _customerCtrl,
                label: 'Customer Name / Phone (Optional)',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _notesCtrl,
                label: 'Billing Notes / Reference (Optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 20),

              // Total Calculation Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Bill Amount',
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600)),
                        Text('$_quantity units @ ${AppFormatters.formatCurrency(_unitPrice)}',
                            style: TextStyle(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                                fontSize: 12)),
                      ],
                    ),
                    Text(
                      AppFormatters.formatCurrency(_totalAmount),
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Complete Billing Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Print & Complete Bill',
                  icon: Icons.receipt_long,
                  onPressed: _completeBilling,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
