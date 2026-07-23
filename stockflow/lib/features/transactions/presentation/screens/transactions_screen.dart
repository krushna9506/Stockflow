import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/transaction_repository.dart';
import '../../../../shared/widgets/state_widgets.dart' as sw;

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.productId});
  final int? productId;

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filter = 'all'; // all / today / week / month

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      setState(() {
        switch (_tabCtrl.index) {
          case 0:
            _filter = 'all';
            break;
          case 1:
            _filter = 'today';
            break;
          case 2:
            _filter = 'week';
            break;
          case 3:
            _filter = 'month';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<List<Transaction>> _loadTransactions() async {
    final businessId = ref.read(activeBusinessIdProvider);
    final repo = ref.read(transactionRepositoryProvider);

    if (widget.productId != null) {
      return repo.getProductTransactions(widget.productId!);
    }

    final now = DateTime.now();
    switch (_filter) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return repo.getTransactionsByDateRange(
            businessId, start, start.add(const Duration(days: 1)));
      case 'week':
        return repo.getTransactionsByDateRange(
            businessId,
            now.subtract(const Duration(days: 7)),
            now.add(const Duration(days: 1)));
      case 'month':
        return repo.getTransactionsByDateRange(
            businessId,
            now.subtract(const Duration(days: 30)),
            now.add(const Duration(days: 1)));
      default:
        return repo.getTransactions(businessId, limit: 200);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.productId != null ? 'Product Transactions' : 'Transactions'),
        bottom: widget.productId == null
            ? TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Today'),
                  Tab(text: 'Week'),
                  Tab(text: 'Month'),
                ],
              )
            : null,
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _loadTransactions(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const sw.LoadingWidget();
          }
          if (snap.hasError) {
            return sw.ErrorWidget(message: snap.error.toString());
          }
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return const sw.EmptyWidget(
              message: 'No transactions found',
              icon: Icons.receipt_long_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _TransactionCard(tx: txs[i]),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIn = AppFormatters.isStockIn(tx.type);
    final color =
        isIn ? const Color(0xFF4CAF50) : const Color(0xFFE91E63);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIn ? Icons.add : Icons.remove,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.transactionTypeLabel(tx.type),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatDateTime(tx.createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (tx.supplier != null || tx.customer != null)
                    Text(
                      tx.supplier ?? tx.customer ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  if (tx.notes != null && tx.notes!.isNotEmpty)
                    Text(
                      tx.notes!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${tx.quantity}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (tx.totalAmount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatCurrency(tx.totalAmount),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${tx.quantityBefore} → ${tx.quantityAfter}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
