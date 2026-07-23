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
      await _api.getTransactions(businessId);
      // Process remote transactions and merge them into local database
    } catch (e) {
      // If offline, just ignore and use local data
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
