import '../../../../shared/widgets/connectivity_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../database/app_database.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;
import '../providers/stock_providers.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          const Center(child: ConnectivityBanner()),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
            onPressed: () => context.push('/categories'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search products...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
              ],
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Category Filter ──────────────────────────────────────────────
          categoriesAsync.when(
            data: (cats) {
              if (cats.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == null,
                        onSelected: (_) => ref
                            .read(selectedCategoryProvider.notifier)
                            .state = null,
                      ),
                    ),
                    ...cats.map((cat) {
                      final color = AppTheme.hexToColor(cat.color);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: selectedCategory == cat.id,
                          selectedColor: color.withValues(alpha: 0.2),
                          checkmarkColor: color,
                          onSelected: (_) => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = selectedCategory == cat.id
                              ? null
                              : cat.id,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 4),

          // ── Product List ──────────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return sw.EmptyWidget(
                    message: 'No products found',
                    subMessage: 'Tap + to add your first product',
                    icon: Icons.inventory_2_outlined,
                    action: () => context.push('/add-product'),
                    actionLabel: 'Add Product',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _ProductCard(product: products[i]),
                );
              },
              loading: () =>
                  const sw.LoadingWidget(message: 'Loading products...'),
              error: (e, _) => sw.ErrorWidget(message: e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color stockColor;
    IconData stockIcon;
    String stockLabel;

    if (product.currentQuantity == 0) {
      stockColor = const Color(0xFFE91E63);
      stockIcon = Icons.remove_circle_outline;
      stockLabel = 'Out of Stock';
    } else if (product.currentQuantity <= product.minimumStock) {
      stockColor = const Color(0xFFF57F17);
      stockIcon = Icons.warning_amber_outlined;
      stockLabel = 'Low Stock';
    } else {
      stockColor = const Color(0xFF4CAF50);
      stockIcon = Icons.check_circle_outline;
      stockLabel = 'In Stock';
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/product-detail/${product.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Product image / placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          product.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(Icons.inventory_2_outlined,
                        color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sell: ${AppFormatters.formatCurrency(product.sellingPrice)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(stockIcon, size: 14, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          stockLabel,
                          style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppFormatters.formatQuantity(product.currentQuantity),
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
