import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getCategoriesForBusiness(int businessId) =>
      (select(categories)
            ..where((t) =>
                t.businessId.equals(businessId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Stream<List<Category>> watchCategoriesForBusiness(int businessId) =>
      (select(categories)
            ..where((t) =>
                t.businessId.equals(businessId) & t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
}
