import 'package:flutter_test/flutter_test.dart';
import 'package:stockflow/core/network/api_client.dart';
import 'package:drift/native.dart';
import 'package:stockflow/database/app_database.dart';
import 'package:stockflow/repositories/business_repository.dart';
import 'package:stockflow/repositories/category_repository.dart';
import 'package:stockflow/repositories/product_repository.dart';
import 'package:stockflow/repositories/transaction_repository.dart';
import 'package:stockflow/core/network/api_services/business_api_service.dart';
import 'package:stockflow/core/network/api_services/category_api_service.dart';
import 'package:stockflow/core/network/api_services/product_api_service.dart';
import 'package:stockflow/core/network/api_services/transaction_api_service.dart';

class FakeBusinessApiService implements BusinessApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryApiService implements CategoryApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProductApiService implements ProductApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionApiService implements TransactionApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late BusinessRepository businessRepo;
  late CategoryRepository categoryRepo;
  late ProductRepository productRepo;
  late TransactionRepository transactionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    businessRepo = BusinessRepository(db, FakeBusinessApiService(), ApiClient());
    categoryRepo = CategoryRepository(db, FakeCategoryApiService());
    productRepo = ProductRepository(db, FakeProductApiService());
    transactionRepo = TransactionRepository(db, FakeTransactionApiService());
  });

  tearDown(() async {
    await db.close();
  });

  test('End-to-End Inventory Flow: Setup -> Category -> Product -> Stock In -> Sell -> Verify Stats & Rules', () async {
    // 1. Setup Business
    final businessId = await businessRepo.createBusiness(
      name: 'Acme Hardware',
      ownerName: 'John Doe',
      phone: '555-0199',
      businessType: 'Hardware',
    );
    expect(businessId, greaterThan(0));

    // 2. Create Category
    final categoryId = await categoryRepo.addCategory(
      businessId: businessId,
      name: 'Power Tools',
      color: '#FF5722',
      icon: 'build',
    );
    expect(categoryId, greaterThan(0));

    // 3. Create Product
    final productId = await productRepo.addProduct(
      businessId: businessId,
      name: 'Cordless Drill 20V',
      categoryId: categoryId,
      purchasePrice: 45.0,
      sellingPrice: 89.99,
      initialQuantity: 10,
      minimumStock: 5,
      sku: 'SKU-DRILL-001',
    );
    expect(productId, greaterThan(0));

    // Verify initial product quantity & dashboard stats
    final productAfterCreate = await productRepo.getProductById(productId);
    expect(productAfterCreate, isNotNull);
    expect(productAfterCreate!.currentQuantity, equals(10));
    expect(await productRepo.getTotalProductCount(businessId), equals(1));
    expect(await productRepo.getTotalStockQuantity(businessId), equals(10));

    // 4. Stock In (+15 units at $44.0 cost price)
    await productRepo.stockIn(
      productId: productId,
      businessId: businessId,
      quantity: 15,
      unitPrice: 44.0,
      supplier: 'DeWalt Wholesale',
      notes: 'Batch #102',
    );

    final productAfterStockIn = await productRepo.getProductById(productId);
    expect(productAfterStockIn!.currentQuantity, equals(25)); // 10 + 15 = 25
    expect(await productRepo.getTotalStockQuantity(businessId), equals(25));

    // 5. Sell / Stock Out (-4 units at $89.99 each)
    await productRepo.sell(
      productId: productId,
      businessId: businessId,
      quantity: 4,
      unitPrice: 89.99,
      customer: 'Bob Builder',
      notes: 'Counter sale',
    );

    final productAfterSale = await productRepo.getProductById(productId);
    expect(productAfterSale!.currentQuantity, equals(21)); // 25 - 4 = 21
    expect(await productRepo.getTotalStockQuantity(businessId), equals(21));

    // 6. Verify Transactions history & daily totals
    final transactions = await transactionRepo.getTransactions(businessId);
    expect(transactions.length, equals(3)); // Opening stock + StockIn + Sale = 3 transactions
    final txTypes = transactions.map((t) => t.type).toSet();
    expect(txTypes.contains('OPENING'), isTrue);
    expect(txTypes.contains('PURCHASE'), isTrue);
    expect(txTypes.contains('SALE'), isTrue);

    // Check offline-first SyncQueue entries
    final pendingSyncs = await db.select(db.syncQueue).get();
    expect(pendingSyncs, isNotEmpty);

    final todaysSalesTotal = await transactionRepo.getTodaysSalesTotal(businessId);
    expect(todaysSalesTotal, closeTo(4 * 89.99, 0.001));

    final todaysStockInQty = await transactionRepo.getTodaysStockInQuantity(businessId);
    expect(todaysStockInQty, greaterThanOrEqualTo(15)); // Includes opening stock if counted or just IN/PURCHASE

    // 7. Verify Inventory Rule constraint: Prevent selling more than available stock
    expect(
      () => productRepo.sell(
        productId: productId,
        businessId: businessId,
        quantity: 100, // 100 > 21 available
        unitPrice: 89.99,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
