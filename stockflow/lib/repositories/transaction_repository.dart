import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../core/network/api_services/transaction_api_service.dart';

class TransactionRepository {
  TransactionRepository(this._db, this._api);
  final AppDatabase _db;
  final TransactionApiService _api;

  Future<void> syncFromServer(int businessId) async {
    try {
      final remoteList = await _api.getTransactions(businessId);
      final existing = await _db.transactionDao.getTransactionsForBusiness(businessId, limit: 1000);
      for (final item in remoteList) {
        final id = item['id'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        final productId = item['product_id'] as int? ?? (item['productId'] as int? ?? 0);
        final typeStr = item['type'] as String? ?? 'sale';
        final type = TransactionType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
          orElse: () => TransactionType.sale,
        );
        final quantity = item['quantity'] as int? ?? 1;
        final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
        final totalPrice = (item['total_price'] as num?)?.toDouble() ?? (quantity * unitPrice);
        final timestampStr = item['timestamp'] as String? ?? item['created_at'] as String?;
        final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) ?? DateTime.now() : DateTime.now();

        final localTx = existing.where((t) => t.id == id).firstOrNull;
        if (localTx == null) {
          await _db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              id: Value(id),
              businessId: businessId,
              productId: productId,
              type: type,
              quantity: quantity,
              unitPrice: unitPrice,
              totalPrice: totalPrice,
              timestamp: Value(timestamp),
            ),
          );
        }
      }
    } catch (e) {
      // Offline fallback
    }
  }

  Future<List<Transaction>> getTransactions(int businessId,
          {int limit = 50, int offset = 0}) =>
      _db.transactionDao
          .getTransactionsForBusiness(businessId, limit: limit, offset: offset);

  Future<List<Transaction>> getProductTransactions(int productId) =>
      _db.transactionDao.getTransactionsForProduct(productId);

  Stream<List<Transaction>> watchRecentTransactions(int businessId,
          {int limit = 10}) =>
      _db.transactionDao.watchRecentTransactions(businessId, limit: limit);

  Future<List<Transaction>> getTransactionsByDateRange(
          int businessId, DateTime from, DateTime to) =>
      _db.transactionDao.getTransactionsByDateRange(businessId, from, to);

  Future<List<Transaction>> getTodaysTransactions(int businessId) =>
      _db.transactionDao.getTodaysTransactions(businessId);

  Future<double> getTodaysSalesTotal(int businessId) =>
      _db.transactionDao.getTodaysSalesTotal(businessId);

  Future<int> getTodaysStockInQuantity(int businessId) =>
      _db.transactionDao.getTodaysStockInQuantity(businessId);

  Future<int> getTodaysSalesCount(int businessId) =>
      _db.transactionDao.getTodaysSalesCount(businessId);
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionApiServiceProvider),
  );
});
