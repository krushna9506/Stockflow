import 'package:drift/drift.dart';

/// Businesses table – stores local + cloud business profile
class Businesses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().nullable()(); // null if offline
  TextColumn get name => text()();
  TextColumn get ownerName => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get businessType => text().withDefault(const Constant('General'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Categories table
@TableIndex(name: 'idx_categories_business', columns: {#businessId})
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#2196F3'))();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  TextColumn get description => text().nullable()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Products table – core product info only
@TableIndex(name: 'idx_products_business', columns: {#businessId})
@TableIndex(name: 'idx_products_category', columns: {#categoryId})
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get businessId => integer().references(Businesses, #id)();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  IntColumn get currentQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minimumStock => integer().withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sku => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// ProductAttributes table – dynamic fields per product
@TableIndex(name: 'idx_product_attrs_product', columns: {#productId})
class ProductAttributes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get fieldKey => text()();
  TextColumn get fieldValue => text().nullable()();
  TextColumn get fieldType => text().withDefault(const Constant('text'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {productId, fieldKey},
      ];
}

/// CustomFields table – business-level field configuration
@TableIndex(name: 'idx_custom_fields_business', columns: {#businessId})
class CustomFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get fieldKey => text()();
  TextColumn get fieldLabel => text()();
  TextColumn get fieldType =>
      text().withDefault(const Constant('text'))(); // text/number/date/dropdown/checkbox/barcode
  TextColumn get dropdownOptions => text().nullable()(); // JSON array for dropdown
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Transactions table – every stock movement
@TableIndex(name: 'idx_tx_business', columns: {#businessId})
@TableIndex(name: 'idx_tx_product', columns: {#productId})
@TableIndex(name: 'idx_tx_created_at', columns: {#createdAt})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get businessId => integer().references(Businesses, #id)();
  TextColumn get type =>
      text()(); // OPENING/PURCHASE/SALE/RETURN_IN/RETURN_OUT/ADJUSTMENT/DAMAGE/TRANSFER
  IntColumn get quantity => integer()();
  IntColumn get quantityBefore => integer()();
  IntColumn get quantityAfter => integer()();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get supplier => text().nullable()();
  TextColumn get customer => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// SyncQueue table – pending cloud sync operations
@TableIndex(name: 'idx_sync_queue_synced', columns: {#isSynced})
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  IntColumn get recordId => integer()();
  TextColumn get operation => text()(); // INSERT/UPDATE/DELETE
  TextColumn get payload => text()(); // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
