import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../database/app_database.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;
import '../../../stock/presentation/providers/stock_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _txFilter = 'ALL'; // 'ALL', 'IN', 'OUT'

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final businessAsync = ref.watch(activeBusinessStreamProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Calculate valuation and health from products
    double totalValuation = 0;
    int healthyCount = 0;
    Map<int, int> categoryCountMap = {};

    productsAsync.whenData((products) {
      for (final p in products) {
        totalValuation += p.currentQuantity * p.sellingPrice;
        if (p.currentQuantity > p.minimumStock) {
          healthyCount++;
        }
        if (p.categoryId != null) {
          categoryCountMap[p.categoryId!] = (categoryCountMap[p.categoryId!] ?? 0) + 1;
        }
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(productsStreamProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              title: businessAsync.when(
                data: (b) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Analytics & Insights',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (b != null)
                      Text(
                        '${b.name} (${b.businessType})',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
                loading: () => const Text('Smart Analytics & Insights'),
                error: (_, __) => const Text('Smart Analytics & Insights'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  tooltip: 'Refresh Analytics',
                  onPressed: () {
                    ref.invalidate(dashboardStatsProvider);
                    ref.invalidate(recentTransactionsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'Full Audit Registry',
                  onPressed: () => context.push('/transactions'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Inventory Valuation Banner Card ──────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primaryContainer, cs.surfaceContainerHighest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EST. INVENTORY VALUATION',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                                  letterSpacing: 1.1,
                                ),
                          ),
                          Icon(Icons.monetization_on_outlined, color: cs.primary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.formatCurrency(totalValuation),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 12),
                      statsAsync.when(
                        data: (stats) {
                          final total = stats.totalProducts;
                          final healthPct = total > 0 ? (healthyCount / total * 100).toStringAsFixed(0) : '100';
                          return Row(
                            children: [
                              Icon(Icons.health_and_safety_outlined, size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Health Status: $healthPct% Healthy',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimaryContainer,
                                    ),
                              ),
                              const Spacer(),
                              if (stats.lowStock > 0 || stats.outOfStock > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${stats.lowStock + stats.outOfStock} Need Attention',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Key Metrics Section Header ──────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text('Core Performance KPIs', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),

            // ── Stats Grid ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: statsAsync.when(
                data: (stats) => SliverGrid(
                  delegate: SliverChildListDelegate([
                    _StatCard(
                      label: 'Total SKU / Products',
                      value: AppFormatters.formatCompact(stats.totalProducts),
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF4F46E5),
                      onTap: () => context.go('/stock'),
                    ),
                    _StatCard(
                      label: 'Total Units in Stock',
                      value: AppFormatters.formatCompact(stats.totalStock),
                      icon: Icons.layers_outlined,
                      color: const Color(0xFF0284C7),
                      onTap: () => context.go('/stock'),
                    ),
                    _StatCard(
                      label: "Today's POS Revenue",
                      value: AppFormatters.formatCurrency(stats.todaysSalesAmount),
                      icon: Icons.point_of_sale_outlined,
                      color: const Color(0xFF0D9488),
                      onTap: () => context.go('/sell'),
                    ),
                    _StatCard(
                      label: "Today's Restock (+Units)",
                      value: AppFormatters.formatCompact(stats.todaysStockIn),
                      icon: Icons.move_to_inbox_outlined,
                      color: const Color(0xFF10B981),
                      onTap: () => context.push('/transactions'),
                    ),
                    _StatCard(
                      label: 'Low Stock Warnings',
                      value: stats.lowStock.toString(),
                      icon: Icons.warning_amber_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/stock'),
                    ),
                    _StatCard(
                      label: 'Out of Stock Alerts',
                      value: stats.outOfStock.toString(),
                      icon: Icons.remove_circle_outline,
                      color: const Color(0xFFEF4444),
                      onTap: () => context.go('/stock'),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.55,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                    child: sw.LoadingWidget(message: 'Calculating metrics...')),
                error: (e, _) => SliverToBoxAdapter(
                    child: sw.ErrorWidget(message: e.toString())),
              ),
            ),

            // ── Category Distribution Insights ───────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text('Inventory Breakdown by Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (cats) {
                    if (cats.isEmpty) {
                      return Text('No categories added yet.', style: TextStyle(color: cs.onSurfaceVariant));
                    }
                    return SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final cat = cats[i];
                          final count = categoryCountMap[cat.id] ?? 0;
                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.name,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.category_outlined, size: 14, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$count SKUs',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Recent Transactions Header with Smart Filters ───────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Audit Activity',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => context.push('/transactions'),
                          child: const Text('See All Logs'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All Activity'),
                            selected: _txFilter == 'ALL',
                            onSelected: (_) => setState(() => _txFilter = 'ALL'),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Restock (+In)'),
                            selected: _txFilter == 'IN',
                            onSelected: (_) => setState(() => _txFilter = 'IN'),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('POS Sales (-Out)'),
                            selected: _txFilter == 'OUT',
                            onSelected: (_) => setState(() => _txFilter = 'OUT'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Filtered Transactions List ──────────────────────────
            recentTxAsync.when(
              data: (txList) {
                var filtered = txList;
                if (_txFilter == 'IN') {
                  filtered = txList.where((t) => AppFormatters.isStockIn(t.type)).toList();
                } else if (_txFilter == 'OUT') {
                  filtered = txList.where((t) => !AppFormatters.isStockIn(t.type)).toList();
                }

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: sw.EmptyWidget(
                        message: 'No transaction activity matching filter',
                        subMessage: 'Restock inventory or complete POS checkout to see logs here',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _TransactionTile(tx: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: sw.LoadingWidget()),
              error: (e, _) => SliverToBoxAdapter(child: sw.ErrorWidget(message: e.toString())),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIn = AppFormatters.isStockIn(tx.type);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isIn ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIn
                ? Icons.move_to_inbox_outlined
                : Icons.point_of_sale_outlined,
            color:
                isIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 22,
          ),
        ),
        title: Text(
          AppFormatters.transactionTypeLabel(tx.type),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          AppFormatters.formatDateTime(tx.createdAt),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIn ? '+' : '-'}${tx.quantity} units',
              style: TextStyle(
                color: isIn
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (tx.totalAmount > 0)
              Text(
                AppFormatters.formatCurrency(tx.totalAmount.toDouble()),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
