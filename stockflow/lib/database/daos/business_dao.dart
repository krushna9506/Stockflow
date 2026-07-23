import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'business_dao.g.dart';

@DriftAccessor(tables: [Businesses])
class BusinessDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessDaoMixin {
  BusinessDao(super.db);

  Future<BusinessesData?> getActiveBusiness() =>
      (select(businesses)..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();

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
