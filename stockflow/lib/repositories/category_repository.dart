import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../core/network/api_services/category_api_service.dart';

class CategoryRepository {
  CategoryRepository(this._db, this._api);
  final AppDatabase _db;
  final CategoryApiService _api;

  Future<void> syncFromServer(int businessId) async {
    try {
      final remoteList = await _api.getCategories(businessId);
      final existing = await _db.categoryDao.getCategoriesForBusiness(businessId);
      for (final item in remoteList) {
        final id = item['id'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        final name = item['name'] as String? ?? 'General';
        final color = item['color'] as String? ?? '#2196F3';
        final icon = item['icon'] as String? ?? 'category';
        final description = item['description'] as String?;

        final localCat = existing.where((c) => c.id == id || c.name == name).firstOrNull;
        if (localCat == null) {
          await _db.categoryDao.insertCategory(
            CategoriesCompanion.insert(
              id: Value(id),
              businessId: businessId,
              name: name,
              color: Value(color),
              icon: Value(icon),
              description: Value(description),
            ),
          );
        } else {
          await _db.categoryDao.updateCategory(
            localCat.toCompanion(true).copyWith(
                  name: Value(name),
                  color: Value(color),
                  icon: Value(icon),
                  description: Value(description),
                ),
          );
        }
      }
    } catch (e) {
      // Offline fallback
    }
  }

  Future<List<Category>> getCategories(int businessId) =>
      _db.categoryDao.getCategoriesForBusiness(businessId);

  Stream<List<Category>> watchCategories(int businessId) =>
      _db.categoryDao.watchCategoriesForBusiness(businessId);

  Future<int> addCategory({
    required int businessId,
    required String name,
    required String color,
    required String icon,
    String? description,
  }) async {
    final id = await _db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        businessId: businessId,
        name: name,
        color: Value(color),
        icon: Value(icon),
        description: Value(description),
      ),
    );
    await _db.enqueueSync(
      entityTable: 'Categories',
      recordId: id,
      operation: 'INSERT',
      payload: '{"id":$id,"name":"$name","businessId":$businessId}',
    );
    return id;
  }

  Future<void> updateCategory(Category category) async {
    await _db.categoryDao.updateCategory(category.toCompanion(true));
    await _db.enqueueSync(
      entityTable: 'Categories',
      recordId: category.id,
      operation: 'UPDATE',
      payload: '{"id":${category.id},"name":"${category.name}"}',
    );
  }

  Future<int> deleteCategory(int id) async {
    final count = await _db.categoryDao.deleteCategory(id);
    if (count > 0) {
      await _db.enqueueSync(
        entityTable: 'Categories',
        recordId: id,
        operation: 'DELETE',
        payload: '{"id":$id}',
      );
    }
    return count;
  }

  Future<Category?> getCategoryById(int id) =>
      _db.categoryDao.getCategoryById(id);
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(categoryApiServiceProvider),
  );
});
