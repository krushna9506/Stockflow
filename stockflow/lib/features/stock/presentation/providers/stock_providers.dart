import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../repositories/category_repository.dart';
import '../../../../repositories/transaction_repository.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_provider.dart';

// ── Products ──────────────────────────────────────────────

final productsStreamProvider =
    StreamProvider.autoDispose<List<Product>>((ref) {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == -1) return Stream.value([]);
  return ref.watch(productRepositoryProvider).watchProducts(businessId);
});

// ── Search & Filter ──────────────────────────────────────────────

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final selectedCategoryProvider =
    StateProvider.autoDispose<int?>((ref) => null);

final filteredProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  final query = ref.watch(searchQueryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final repo = ref.watch(productRepositoryProvider);

  if (businessId == -1) return [];

  if (query.isNotEmpty) {
    return repo.searchProducts(businessId, query);
  } else if (categoryId != null) {
    return repo.getProductsByCategory(businessId, categoryId);
  } else {
    return repo.getProducts(businessId);
  }
});

// ── Single Product ──────────────────────────────────────────────

final productDetailProvider =
    FutureProvider.autoDispose.family<Product?, int>((ref, id) {
  return ref.watch(productRepositoryProvider).getProductById(id);
});

final productAttributesProvider =
    FutureProvider.autoDispose.family<List<ProductAttribute>, int>(
        (ref, productId) {
  return ref
      .watch(productRepositoryProvider)
      .getProductAttributes(productId);
});

// ── Product Transactions ──────────────────────────────────────────────

final productTransactionsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>(
        (ref, productId) {
  return ref
      .watch(transactionRepositoryProvider)
      .getProductTransactions(productId);
});

// ── Categories for filter ──────────────────────────────────────────────

final categoriesProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == -1) return Stream.value([]);
  return ref.watch(categoryRepositoryProvider).watchCategories(businessId);
});

final enabledCustomFieldsProvider =
    StreamProvider.autoDispose<List<CustomField>>((ref) {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == -1) return Stream.value([]);
  return ref
      .watch(appDatabaseProvider)
      .customFieldDao
      .watchEnabledFields(businessId);
});
