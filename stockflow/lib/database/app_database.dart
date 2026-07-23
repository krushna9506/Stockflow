import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tables.dart';
import 'daos/business_dao.dart';
import 'daos/category_dao.dart';
import 'daos/product_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/custom_field_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Businesses,
    Categories,
    Products,
    ProductAttributes,
    CustomFields,
    Transactions,
    SyncQueue,
  ],
  daos: [
    BusinessDao,
    CategoryDao,
    ProductDao,
    TransactionDao,
    CustomFieldDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await customStatement('CREATE INDEX IF NOT EXISTS idx_categories_business ON categories (business_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_products_business ON products (business_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_product_attrs_product ON product_attributes (product_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_custom_fields_business ON custom_fields (business_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_tx_business ON transactions (business_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_tx_product ON transactions (product_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_tx_created_at ON transactions (created_at);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_queue_synced ON sync_queue (is_synced);');
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'stockflow_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// Export database path for backup
  Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'stockflow_db.sqlite');
  }

  /// Enqueue an offline action for future synchronization with backend
  Future<int> enqueueSync({
    required String entityTable,
    required int recordId,
    required String operation,
    required String payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityTable: entityTable,
        recordId: recordId,
        operation: operation,
        payload: payload,
      ),
    );
  }

  /// Get pending sync items that have not exceeded max retries
  Future<List<SyncQueueData>> getPendingSyncItems() {
    return (select(syncQueue)
          ..where((t) => t.isSynced.equals(false) & t.retryCount.isSmallerThanValue(5))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// Mark a sync item as successfully synced
  Future<int> markSynced(int id) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        isSynced: const Value(true),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Increment retry count for a failed sync item
  Future<int> incrementSyncRetry(int id) async {
    final item = await (select(syncQueue)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item == null) return 0;
    
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(item.retryCount + 1),
      ),
    );
  }

  /// Get count of pending items
  Future<int> getSyncQueueCount() {
    final countExp = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..addColumns([countExp])
      ..where(syncQueue.isSynced.equals(false) & syncQueue.retryCount.isSmallerThanValue(5));
    return query.map((row) => row.read(countExp)).getSingle().then((val) => val ?? 0);
  }
}
