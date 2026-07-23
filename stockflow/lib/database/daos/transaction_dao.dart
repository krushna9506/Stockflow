import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<Transaction>> getTransactionsForBusiness(int businessId,
      {int limit = 50, int offset = 0}) =>
      (select(transactions)
            ..where((t) => t.businessId.equals(businessId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
            ])
            ..limit(limit, offset: offset))
          .get();

  Future<List<Transaction>> getTransactionsForProduct(int productId) =>
      (select(transactions)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<Transaction>> watchRecentTransactions(int businessId,
      {int limit = 10}) =>
      (select(transactions)
            ..where((t) => t.businessId.equals(businessId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Future<List<Transaction>> getTransactionsByDateRange(
          int businessId, DateTime from, DateTime to) =>
      (select(transactions)
            ..where((t) =>
                t.businessId.equals(businessId) &
                t.createdAt.isBiggerOrEqualValue(from) &
                t.createdAt.isSmallerOrEqualValue(to))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Transaction>> getTodaysTransactions(int businessId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTransactionsByDateRange(businessId, startOfDay, endOfDay);
  }

  Future<List<Transaction>> getTodaysSales(int businessId) async {
    final all = await getTodaysTransactions(businessId);
    return all
        .where((t) => t.type == 'SALE' || t.type == 'RETURN_OUT')
        .toList();
  }

  Future<List<Transaction>> getTodaysStockIn(int businessId) async {
    final all = await getTodaysTransactions(businessId);
    return all
        .where(
            (t) => t.type == 'PURCHASE' || t.type == 'RETURN_IN' || t.type == 'OPENING')
        .toList();
  }

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<double> getTodaysSalesTotal(int businessId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final sumExp = transactions.totalAmount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sumExp])
      ..where(transactions.businessId.equals(businessId) &
              transactions.type.isIn(['SALE', 'RETURN_OUT']) &
              transactions.createdAt.isBiggerOrEqualValue(startOfDay) &
              transactions.createdAt.isSmallerOrEqualValue(endOfDay));
    return await query.map((row) => row.read(sumExp)).getSingle() ?? 0.0;
  }

  Future<int> getTodaysStockInQuantity(int businessId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final sumExp = transactions.quantity.sum();
    final query = selectOnly(transactions)
      ..addColumns([sumExp])
      ..where(transactions.businessId.equals(businessId) &
              transactions.type.isIn(['PURCHASE', 'RETURN_IN', 'OPENING']) &
              transactions.createdAt.isBiggerOrEqualValue(startOfDay) &
              transactions.createdAt.isSmallerOrEqualValue(endOfDay));
    return await query.map((row) => row.read(sumExp)).getSingle() ?? 0;
  }

  Future<int> getTodaysSalesCount(int businessId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final countExp = transactions.id.count();
    final query = selectOnly(transactions)
      ..addColumns([countExp])
      ..where(transactions.businessId.equals(businessId) &
              transactions.type.equals('SALE') &
              transactions.createdAt.isBiggerOrEqualValue(startOfDay) &
              transactions.createdAt.isSmallerOrEqualValue(endOfDay));
    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
  }
}
