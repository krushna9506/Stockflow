import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'business_dao.g.dart';

@DriftAccessor(tables: [Businesses])
class BusinessDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessDaoMixin {
  BusinessDao(super.db);

  Future<BusinessesData?> getActiveBusiness() async {
    final active = await (select(businesses)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    if (active != null) return active;
    final first = await (select(businesses)..limit(1)).getSingleOrNull();
    if (first != null) {
      await updateBusiness(first.toCompanion(true).copyWith(isActive: const Value(true)));
    }
    return first;
  }

  Future<List<BusinessesData>> getAllBusinesses() => select(businesses).get();

  Future<int> insertBusiness(BusinessesCompanion entry) =>
      into(businesses).insert(entry);

  Future<bool> updateBusiness(BusinessesCompanion entry) =>
      update(businesses).replace(entry);

  Future<int> deleteBusiness(int id) =>
      (delete(businesses)..where((t) => t.id.equals(id))).go();

  Stream<BusinessesData?> watchActiveBusiness() =>
      (select(businesses)..where((t) => t.isActive.equals(true)))
          .watchSingleOrNull();
}
