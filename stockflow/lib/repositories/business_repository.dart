import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../core/network/api_services/business_api_service.dart';

class BusinessRepository {
  BusinessRepository(this._db, this._api);
  final AppDatabase _db;
  final BusinessApiService _api;

  Future<void> syncFromServer() async {
    try {
      await _api.getBusinesses();
      // Process remote businesses and merge them into local database
    } catch (e) {
      // If offline, just ignore and use local data
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
