import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../core/network/api_services/business_api_service.dart';

class BusinessRepository {
  BusinessRepository(this._db, this._api);
  final AppDatabase _db;
  final BusinessApiService _api;

  Future<BusinessesData?> syncFromServer() async {
    try {
      final remoteList = await _api.getBusinesses();
      if (remoteList.isEmpty) return null;

      BusinessesData? firstBusiness;
      for (final item in remoteList) {
        final name = item['name'] as String? ?? 'My Business';
        final ownerName = item['owner_name'] as String? ?? 'Owner';
        final phone = item['phone'] as String? ?? '';
        final email = item['email'] as String?;
        final address = item['address'] as String?;
        final businessType = item['business_type'] as String? ?? 'General';
        final id = item['id'] as int? ?? DateTime.now().millisecondsSinceEpoch;

        final existingList = await _db.businessDao.getAllBusinesses();
        var localB = existingList.where((b) => b.id == id || b.name == name).firstOrNull;

        if (localB == null) {
          await _db.businessDao.insertBusiness(
            BusinessesCompanion.insert(
              id: Value(id),
              name: name,
              ownerName: ownerName,
              phone: phone,
              email: Value(email),
              address: Value(address),
              businessType: Value(businessType),
              isActive: const Value(true),
            ),
          );
          localB = (await _db.businessDao.getAllBusinesses()).where((b) => b.id == id || b.name == name).firstOrNull;
        }
        firstBusiness ??= localB;
      }
      return firstBusiness ?? await getActiveBusiness();
    } catch (e) {
      // If offline or error, use local active business
      return getActiveBusiness();
    }
  }

  Future<BusinessesData?> getActiveBusiness() =>
      _db.businessDao.getActiveBusiness();

  Stream<BusinessesData?> watchActiveBusiness() =>
      _db.businessDao.watchActiveBusiness();

  Future<int> createBusiness({
    required String name,
    required String ownerName,
    required String phone,
    String? email,
    String? address,
    String? logoPath,
    required String businessType,
  }) async {
    // Deactivate all existing
    final existing = await _db.businessDao.getAllBusinesses();
    for (final b in existing) {
      await _db.businessDao
          .updateBusiness(b.toCompanion(true).copyWith(isActive: const Value(false)));
    }
    final id = await _db.businessDao.insertBusiness(
      BusinessesCompanion.insert(
        name: name,
        ownerName: ownerName,
        phone: phone,
        email: Value(email),
        address: Value(address),
        logoPath: Value(logoPath),
        businessType: Value(businessType),
        isActive: const Value(true),
      ),
    );
    await _db.enqueueSync(
      entityTable: 'Businesses',
      recordId: id,
      operation: 'INSERT',
      payload: '{"id":$id,"name":"$name","type":"$businessType"}',
    );
    return id;
  }

  Future<void> updateBusiness(BusinessesData business) async {
    await _db.businessDao.updateBusiness(
      business.toCompanion(true).copyWith(
            updatedAt: Value(DateTime.now()),
          ),
    );
    await _db.enqueueSync(
      entityTable: 'Businesses',
      recordId: business.id,
      operation: 'UPDATE',
      payload: '{"id":${business.id},"name":"${business.name}"}',
    );
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(businessApiServiceProvider),
  );
});
