import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../repositories/business_repository.dart';
import '../../../../repositories/transaction_repository.dart';

final activeBusinessStreamProvider = StreamProvider.autoDispose<BusinessesData?>((ref) {
  return ref.watch(businessRepositoryProvider).watchActiveBusiness();
});

final recentTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == -1) return Stream.value([]);
  return ref
      .watch(transactionRepositoryProvider)
      .watchRecentTransactions(businessId, limit: 5);
});

class DashboardStats {
  const DashboardStats({
    required this.totalProducts,
    required this.totalStock,
    required this.lowStock,
    required this.outOfStock,
    required this.todaysStockIn,
    required this.todaysSales,
    required this.todaysSalesAmount,
  });

  final int totalProducts;
  final int totalStock;
  final int lowStock;
  final int outOfStock;
  final int todaysStockIn;
  final int todaysSales;
  final double todaysSalesAmount;
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == -1) {
    return const DashboardStats(
      totalProducts: 0,
      totalStock: 0,
      lowStock: 0,
      outOfStock: 0,
      todaysStockIn: 0,
      todaysSales: 0,
      todaysSalesAmount: 0,
    );
  }

  final productRepo = ref.watch(productRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  final results = await Future.wait<dynamic>([
    productRepo.getTotalProductCount(businessId),
    productRepo.getTotalStockQuantity(businessId),
    productRepo.getLowStockCount(businessId),
    productRepo.getOutOfStockCount(businessId),
    txRepo.getTodaysStockInQuantity(businessId),
    txRepo.getTodaysSalesTotal(businessId),
    ref.read(transactionRepositoryProvider).getTodaysSalesCount(businessId),
  ]);

  return DashboardStats(
    totalProducts: results[0] as int,
    totalStock: results[1] as int,
    lowStock: results[2] as int,
    outOfStock: results[3] as int,
    todaysStockIn: results[4] as int,
    todaysSales: results[6] as int,
    todaysSalesAmount: (results[5] as num).toDouble(),
  );
});
