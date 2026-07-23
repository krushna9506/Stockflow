import 'package:drift/drift.dart';
import '../tables/tables.dart';
import '../app_database.dart';

part 'custom_field_dao.g.dart';

@DriftAccessor(tables: [CustomFields])
class CustomFieldDao extends DatabaseAccessor<AppDatabase>
    with _$CustomFieldDaoMixin {
  CustomFieldDao(super.db);

  Future<List<CustomField>> getEnabledFields(int businessId) =>
      (select(customFields)
            ..where((t) =>
                t.businessId.equals(businessId) & t.isEnabled.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<CustomField>> getAllFields(int businessId) =>
      (select(customFields)
            ..where((t) => t.businessId.equals(businessId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<CustomField>> watchEnabledFields(int businessId) =>
      (select(customFields)
            ..where((t) =>
                t.businessId.equals(businessId) & t.isEnabled.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<int> insertField(CustomFieldsCompanion entry) =>
      into(customFields).insert(entry);

  Future<bool> updateField(CustomFieldsCompanion entry) =>
      update(customFields).replace(entry);

  Future<int> deleteField(int id) =>
      (delete(customFields)..where((t) => t.id.equals(id))).go();

  Future<void> setFieldEnabled(int id, bool enabled) =>
      (update(customFields)..where((t) => t.id.equals(id)))
          .write(CustomFieldsCompanion(isEnabled: Value(enabled)));

  Future<int> countFieldsForBusiness(int businessId) async {
    final result = await (select(customFields)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    return result.length;
  }
}
