import 'package:flutter/material.dart';
import '../../../../core/widgets/local_image_renderer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;
import '../providers/stock_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final attrsAsync = ref.watch(productAttributesProvider(productId));
    final txData = ref.watch(productTransactionsProvider(productId));


    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => productAsync.whenData(
              (product) {
                if (product != null) {
                  context.push('/add-product',
                      extra: {'product': product});
                }
              },
            ),
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const sw.EmptyWidget(message: 'Product not found');
          }
          final cs = Theme.of(context).colorScheme;

          Color stockColor;
          if (product.currentQuantity == 0) {
            stockColor = const Color(0xFFE91E63);
          } else if (product.currentQuantity <= product.minimumStock) {
            stockColor = const Color(0xFFF57F17);
          } else {
            stockColor = const Color(0xFF4CAF50);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: cs.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      product.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: LocalImageRenderer(
                                  imagePath: product.imagePath!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : _PlaceholderIcon(cs),
                      const SizedBox(height: 16),
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (product.sku != null) ...[
                        const SizedBox(height: 4),
                        Text('SKU: ${product.sku}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stock Card ──────────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  label: 'Current Stock',
                                  value: product.currentQuantity.toString(),
                                  color: stockColor,
                                  large: true,
                                ),
                              ),
                              Expanded(
                                child: _InfoTile(
                                  label: 'Min Stock',
                                  value: product.minimumStock.toString(),
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Price Card ──────────────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  label: 'Purchase Price',
                                  value: AppFormatters.formatCurrency(
                                      product.purchasePrice),
                                  color: cs.onSurface,
                                ),
                              ),
                              Expanded(
                                child: _InfoTile(
                                  label: 'Selling Price',
                                  value: AppFormatters.formatCurrency(
                                      product.sellingPrice),
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Attributes ──────────────────────────────────────────────
                      attrsAsync.when(
                        data: (attrs) {
                          if (attrs.isEmpty) return const SizedBox.shrink();
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Additional Details',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const Divider(height: 20),
                                  ...attrs.map((a) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(a.fieldKey,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color: cs.onSurfaceVariant)),
                                            Text(a.fieldValue ?? '–',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),
                      // ── Action Buttons ──────────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  context.push('/stock-in/${product.id}'),
                              icon: const Icon(Icons.move_to_inbox),
                              label: const Text('Stock In'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: product.currentQuantity > 0
                                  ? () => context.go('/sell')
                                  : null,
                              icon: const Icon(Icons.point_of_sale),
                              label: const Text('Sell'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF009688),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, ref, product.id),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Product'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                          ),
                        ),
                      ),

                      // ── Transaction History ──────────────────────────────────────────────
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transaction History',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => context.push('/transactions',
                                extra: {'productId': product.id}),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      txData.when(
                        data: (txs) {
                          final recent = txs.take(5).toList();
                          if (recent.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: sw.EmptyWidget(
                                message: 'No transactions yet',
                                icon: Icons.receipt_long_outlined,
                              ),
                            );
                          }
                          return Column(
                            children: recent
                                .map((tx) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        AppFormatters.isStockIn(tx.type)
                                            ? Icons.add_circle_outline
                                            : Icons.remove_circle_outline,
                                        color: AppFormatters.isStockIn(tx.type)
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFE91E63),
                                      ),
                                      title: Text(AppFormatters
                                          .transactionTypeLabel(tx.type)),
                                      subtitle: Text(AppFormatters
                                          .formatDateTime(tx.createdAt)),
                                      trailing: Text(
                                        '${AppFormatters.isStockIn(tx.type) ? '+' : '-'}${tx.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppFormatters.isStockIn(
                                                  tx.type)
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFE91E63),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                        loading: () => const sw.LoadingWidget(),
                        error: (e, _) => sw.ErrorWidget(message: e.toString()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const sw.LoadingWidget(),
        error: (e, _) => sw.ErrorWidget(message: e.toString()),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text(
            'This will soft-delete the product. All transaction history will be preserved.'),
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
      await ref.read(productRepositoryProvider).deleteProduct(productId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
        context.pop();
      }
    }
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon(this.cs);
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.inventory_2_outlined, size: 48, color: cs.primary),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (large
                  ? Theme.of(context).textTheme.headlineSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
