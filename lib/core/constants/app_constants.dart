class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String tenantsCollection = 'tenants';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String movementsCollection = 'movements';

  // Firestore field names
  static const String fieldName = 'name';
  static const String fieldDescription = 'description';
  static const String fieldCategoryId = 'categoryId';
  static const String fieldSku = 'sku';
  static const String fieldQuantity = 'quantity';
  static const String fieldThreshold = 'threshold';
  static const String fieldPrice = 'price';
  static const String fieldProductId = 'productId';
  static const String fieldType = 'type';
  static const String fieldNote = 'note';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldTenantId = 'tenantId';

  // Movement types
  static const String movementIn = 'in';
  static const String movementOut = 'out';

  // Notification
  static const String notifChannelId = 'stock_alerts';
  static const String notifChannelName = 'Alertes de stock';
  static const String notifChannelDesc = 'Notifications pour produits sous seuil';

  // Shared Prefs keys
  static const String prefTenantId = 'tenant_id';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
}
