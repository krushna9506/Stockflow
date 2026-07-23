class AppConstants {
  static const String appName = 'StockFlow';
  static const String appVersion = '1.1.0';

  // SharedPreferences Keys
  static const String keyBusinessId = 'business_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyIsOffline = 'is_offline';
  static const String keyThemeMode = 'theme_mode';
  static const String keyBusinessSetupDone = 'business_setup_done';

  // Transaction Types
  static const String txOpening = 'OPENING';
  static const String txPurchase = 'PURCHASE';
  static const String txSale = 'SALE';
  static const String txReturnIn = 'RETURN_IN';
  static const String txReturnOut = 'RETURN_OUT';
  static const String txAdjustment = 'ADJUSTMENT';
  static const String txDamage = 'DAMAGE';
  static const String txTransfer = 'TRANSFER';

  // Business Types
  static const List<String> businessTypes = [
    'Grocery',
    'Hardware',
    'Electronics',
    'Medical',
    'Garments',
    'Automobile',
    'Furniture',
    'General',
    'Custom',
  ];

  // Default field keys per business type
  static const Map<String, List<String>> defaultFieldsByType = {
    'Grocery': ['brand', 'expiryDate', 'batchNumber', 'barcode'],
    'Electronics': ['brand', 'warranty', 'modelNumber', 'serialNumber', 'barcode'],
    'Hardware': ['brand', 'barcode', 'storageLocation'],
    'Medical': ['brand', 'expiryDate', 'batchNumber', 'manufacturer'],
    'Garments': ['brand', 'barcode'],
    'Automobile': ['brand', 'barcode', 'storageLocation'],
    'Furniture': ['brand', 'storageLocation'],
    'General': ['brand', 'barcode'],
    'Custom': [],
  };

  // All available field definitions
  static const List<Map<String, String>> availableFields = [
    {'key': 'brand', 'label': 'Brand', 'type': 'text'},
    {'key': 'barcode', 'label': 'Barcode', 'type': 'barcode'},
    {'key': 'expiryDate', 'label': 'Expiry Date', 'type': 'date'},
    {'key': 'warranty', 'label': 'Warranty', 'type': 'text'},
    {'key': 'batchNumber', 'label': 'Batch Number', 'type': 'text'},
    {'key': 'serialNumber', 'label': 'Serial Number', 'type': 'text'},
    {'key': 'modelNumber', 'label': 'Model Number', 'type': 'text'},
    {'key': 'manufacturer', 'label': 'Manufacturer', 'type': 'text'},
    {'key': 'storageLocation', 'label': 'Storage Location', 'type': 'text'},
    {'key': 'supplier', 'label': 'Supplier', 'type': 'text'},
    {'key': 'notes', 'label': 'Notes', 'type': 'text'},
  ];
}
