import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Categories, ProductAttributes])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  // ── Products ──────────────────────────────────────────────

  Future<List<Product>> getProductsForBusiness(int businessId) =>
      (select(products)
            ..where(
                (t) => t.businessId.equals(businessId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<Product>> watchProductsForBusiness(int businessId) =>
      (select(products)
            ..where(
                (t) => t.businessId.equals(businessId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<List<Product>> searchProducts(int businessId, String query) =>
      (select(products)
            ..where((t) =>
                t.businessId.equals(businessId) &
                t.isActive.equals(true) &
                t.name.like('%$query%'))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<Product>> getProductsByCategory(
          int businessId, int categoryId) =>
      (select(products)
            ..where((t) =>
                t.businessId.equals(businessId) &
                t.isActive.equals(true) &
                t.categoryId.equals(categoryId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<Product>> getLowStockProducts(int businessId) =>
      (select(products)
            ..where((t) =>
                t.businessId.equals(businessId) &
                t.isActive.equals(true) &
                t.currentQuantity.isSmallerThanValue(
                    0) // handled in app layer comparing to minimumStock
            ))
          .get();

  Future<Product?> getProductById(int id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<bool> updateProduct(ProductsCompanion entry) =>
      update(products).replace(entry);

  Future<void> updateQuantity(int productId, int newQuantity) =>
      (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          currentQuantity: Value(newQuantity),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> deleteProduct(int id) =>
      (update(products)..where((t) => t.id.equals(id))).write(
        const ProductsCompanion(isActive: Value(false)),
      );

  // ── Stats ──────────────────────────────────────────────

  Future<int> getTotalProductCount(int businessId) async {
    final countExp = products.id.count();
    final query = selectOnly(products)
      ..addColumns([countExp])
      ..where(products.businessId.equals(businessId) & products.isActive.equals(true));
    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
  }

  Future<int> getTotalStockQuantity(int businessId) async {
    final sumExp = products.currentQuantity.sum();
    final query = selectOnly(products)
      ..addColumns([sumExp])
      ..where(products.businessId.equals(businessId) & products.isActive.equals(true));
    return await query.map((row) => row.read(sumExp)).getSingle() ?? 0;
  }

  // ── ProductAttributes ──────────────────────────────────────────────

  Future<List<ProductAttribute>> getAttributesForProduct(int productId) =>
      (select(productAttributes)
            ..where((t) => t.productId.equals(productId)))
          .get();

  Future<void> upsertAttribute(ProductAttributesCompanion entry) async {
    await into(productAttributes).insertOnConflictUpdate(entry);
  }

  Future<void> deleteAttributesForProduct(int productId) async {
    await (delete(productAttributes)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }
}
