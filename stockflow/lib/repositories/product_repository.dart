import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../core/network/api_services/product_api_service.dart';

class ProductRepository {
  ProductRepository(this._db, this._api);
  final AppDatabase _db;
  final ProductApiService _api;

  Future<void> syncFromServer(int businessId) async {
    try {
      await _api.getProducts(businessId);
      // Process remote products and merge them into local database
    } catch (e) {
      // If offline, just ignore and use local data
    }
  }

  Future<List<Product>> getProducts(int businessId) =>
      _db.productDao.getProductsForBusiness(businessId);

  Stream<List<Product>> watchProducts(int businessId) =>
      _db.productDao.watchProductsForBusiness(businessId);

  Future<List<Product>> searchProducts(int businessId, String query) =>
      _db.productDao.searchProducts(businessId, query);

  Future<List<Product>> getProductsByCategory(
          int businessId, int categoryId) =>
      _db.productDao.getProductsByCategory(businessId, categoryId);

  Future<Product?> getProductById(int id) =>
      _db.productDao.getProductById(id);

  Future<int> addProduct({
    required int businessId,
    required String name,
    int? categoryId,
    required double purchasePrice,
    required double sellingPrice,
    required int initialQuantity,
    required int minimumStock,
    String? imagePath,
    String? sku,
    Map<String, String>? attributes,
  }) async {
    final productId = await _db.productDao.insertProduct(
      ProductsCompanion.insert(
        businessId: businessId,
        name: name,
        categoryId: Value(categoryId),
        purchasePrice: Value(purchasePrice),
        sellingPrice: Value(sellingPrice),
        currentQuantity: Value(initialQuantity),
        minimumStock: Value(minimumStock),
        imagePath: Value(imagePath),
        sku: Value(sku),
      ),
    );

    // Save opening stock transaction if qty > 0
    if (initialQuantity > 0) {
      await _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          productId: productId,
          businessId: businessId,
          type: AppConstants.txOpening,
          quantity: initialQuantity,
          quantityBefore: 0,
          quantityAfter: initialQuantity,
          unitPrice: Value(purchasePrice),
          totalAmount: Value(purchasePrice * initialQuantity),
        ),
      );
    }

    // Save attributes
    if (attributes != null) {
      for (final entry in attributes.entries) {
        await _db.productDao.upsertAttribute(
          ProductAttributesCompanion.insert(
            productId: productId,
            fieldKey: entry.key,
            fieldValue: Value(entry.value),
          ),
        );
      }
    }

    await _db.enqueueSync(
      entityTable: 'Products',
      recordId: productId,
      operation: 'INSERT',
      payload: '{"id":$productId,"name":"$name","currentQuantity":$initialQuantity}',
    );

    return productId;
  }

  Future<void> updateProduct({
    required Product product,
    Map<String, String>? attributes,
  }) async {
    await _db.productDao.updateProduct(
      product
          .toCompanion(true)
          .copyWith(updatedAt: Value(DateTime.now())),
    );

    if (attributes != null) {
      await _db.productDao.deleteAttributesForProduct(product.id);
      for (final entry in attributes.entries) {
        await _db.productDao.upsertAttribute(
          ProductAttributesCompanion.insert(
            productId: product.id,
            fieldKey: entry.key,
            fieldValue: Value(entry.value),
          ),
        );
      }
    }

    await _db.enqueueSync(
      entityTable: 'Products',
      recordId: product.id,
      operation: 'UPDATE',
      payload: '{"id":${product.id},"name":"${product.name}"}',
    );
  }

  Future<int> deleteProduct(int id) async {
    final count = await _db.productDao.deleteProduct(id);
    if (count > 0) {
      await _db.enqueueSync(
        entityTable: 'Products',
        recordId: id,
        operation: 'DELETE',
        payload: '{"id":$id}',
      );
    }
    return count;
  }

  Future<List<ProductAttribute>> getProductAttributes(int productId) =>
      _db.productDao.getAttributesForProduct(productId);

  // ── Stock Operations ──────────────────────────────────────────────

  /// Stock In: increases quantity and creates PURCHASE transaction
  Future<void> stockIn({
    required int productId,
    required int businessId,
    required int quantity,
    required double unitPrice,
    String? supplier,
    String? notes,
    String type = AppConstants.txPurchase,
  }) async {
    final product = await _db.productDao.getProductById(productId);
    if (product == null) throw Exception('Product not found');

    final newQty = product.currentQuantity + quantity;
    await _db.productDao.updateQuantity(productId, newQty);

    await _db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        productId: productId,
        businessId: businessId,
        type: type,
        quantity: quantity,
        quantityBefore: product.currentQuantity,
        quantityAfter: newQty,
        unitPrice: Value(unitPrice),
        totalAmount: Value(unitPrice * quantity),
        supplier: Value(supplier),
        notes: Value(notes),
      ),
    );

    await _db.enqueueSync(
      entityTable: 'Products',
      recordId: productId,
      operation: 'UPDATE',
      payload: '{"id":$productId,"currentQuantity":$newQty,"action":"stockIn"}',
    );
  }

  /// Sell: decreases quantity and creates SALE transaction
  Future<void> sell({
    required int productId,
    required int businessId,
    required int quantity,
    required double unitPrice,
    String? customer,
    String? notes,
  }) async {
    final product = await _db.productDao.getProductById(productId);
    if (product == null) throw Exception('Product not found');
    if (product.currentQuantity < quantity) {
      throw Exception(
          'Insufficient stock. Available: ${product.currentQuantity}');
    }

    final newQty = product.currentQuantity - quantity;
    await _db.productDao.updateQuantity(productId, newQty);

    await _db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        productId: productId,
        businessId: businessId,
        type: AppConstants.txSale,
        quantity: quantity,
        quantityBefore: product.currentQuantity,
        quantityAfter: newQty,
        unitPrice: Value(unitPrice),
        totalAmount: Value(unitPrice * quantity),
        customer: Value(customer),
        notes: Value(notes),
      ),
    );

    await _db.enqueueSync(
      entityTable: 'Products',
      recordId: productId,
      operation: 'UPDATE',
      payload: '{"id":$productId,"currentQuantity":$newQty,"action":"sell"}',
    );
  }

  // ── Dashboard Stats ──────────────────────────────────────────────

  Future<int> getTotalProductCount(int businessId) =>
      _db.productDao.getTotalProductCount(businessId);

  Future<int> getTotalStockQuantity(int businessId) =>
      _db.productDao.getTotalStockQuantity(businessId);

  Future<int> getLowStockCount(int businessId) async {
    final products = await getProducts(businessId);
    return products
        .where(
            (p) => p.currentQuantity <= p.minimumStock && p.currentQuantity > 0)
        .length;
  }

  Future<int> getOutOfStockCount(int businessId) async {
    final products = await getProducts(businessId);
    return products.where((p) => p.currentQuantity == 0).length;
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(productApiServiceProvider),
  );
});
