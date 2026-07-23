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
      await _api.getCategories(businessId);
      // Process remote categories and merge them into local database
    } catch (e) {
      // If offline, just ignore and use local data
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
