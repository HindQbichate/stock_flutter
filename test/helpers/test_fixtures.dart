// test/helpers/test_fixtures.dart
//
// Shared test data and helpers used across all test suites.

import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';

// ─── Product Fixtures ──────────────────────────────────────────────────────

class ProductFixtures {
  static ProductEntity get coca => ProductEntity(
        id: 'prod-coca-001',
        tenantId: 'tenant-001',
        name: 'Coca-Cola 1L',
        categoryId: 'cat-boissons',
        categoryName: 'Boissons',
        sku: 'CC-1L-001',
        quantity: 50,
        threshold: 10,
        price: 1500.0,
        description: 'Boisson gazeuse 1 litre',
        createdAt: DateTime(2024, 1, 1),
      );

  static ProductEntity get fanta => ProductEntity(
        id: 'prod-fanta-001',
        tenantId: 'tenant-001',
        name: 'Fanta Orange 1L',
        categoryId: 'cat-boissons',
        categoryName: 'Boissons',
        sku: 'FA-OR-001',
        quantity: 30,
        threshold: 8,
        price: 1200.0,
        createdAt: DateTime(2024, 1, 1),
      );

  static ProductEntity get lowStockProduct => ProductEntity(
        id: 'prod-low-001',
        tenantId: 'tenant-001',
        name: 'Produit Critique',
        categoryId: 'cat-epicerie',
        categoryName: 'Épicerie',
        sku: 'LOW-001',
        quantity: 3,
        threshold: 10,
        price: 500.0,
        createdAt: DateTime(2024, 1, 1),
      );

  static ProductEntity get outOfStockProduct => ProductEntity(
        id: 'prod-out-001',
        tenantId: 'tenant-001',
        name: 'Produit Épuisé',
        categoryId: 'cat-epicerie',
        categoryName: 'Épicerie',
        sku: 'OUT-001',
        quantity: 0,
        threshold: 5,
        price: 300.0,
        createdAt: DateTime(2024, 1, 1),
      );

  static List<ProductEntity> get sampleList => [
        coca,
        fanta,
        lowStockProduct,
        outOfStockProduct,
      ];
}

// ─── Category Fixtures ─────────────────────────────────────────────────────

class CategoryFixtures {
  static CategoryEntity get boissons => CategoryEntity(
        id: 'cat-boissons',
        tenantId: 'tenant-001',
        name: 'Boissons',
        description: 'Toutes les boissons',
        color: '#2196F3',
        createdAt: DateTime(2024, 1, 1),
      );

  static CategoryEntity get epicerie => CategoryEntity(
        id: 'cat-epicerie',
        tenantId: 'tenant-001',
        name: 'Épicerie',
        color: '#4CAF50',
        createdAt: DateTime(2024, 1, 1),
      );

  static List<CategoryEntity> get sampleList => [boissons, epicerie];
}

// ─── Movement Fixtures ─────────────────────────────────────────────────────

class MovementFixtures {
  static MovementEntity inboundCoca({int quantity = 20}) => MovementEntity(
        id: 'mov-in-001',
        tenantId: 'tenant-001',
        productId: 'prod-coca-001',
        productName: 'Coca-Cola 1L',
        productSku: 'CC-1L-001',
        type: MovementType.inbound,
        quantity: quantity,
        unitPrice: 1200.0,
        note: 'Livraison fournisseur',
        createdAt: DateTime(2024, 6, 1, 9, 0),
      );

  static MovementEntity outboundCoca({int quantity = 5}) => MovementEntity(
        id: 'mov-out-001',
        tenantId: 'tenant-001',
        productId: 'prod-coca-001',
        productName: 'Coca-Cola 1L',
        productSku: 'CC-1L-001',
        type: MovementType.outbound,
        quantity: quantity,
        unitPrice: 1500.0,
        createdAt: DateTime(2024, 6, 1, 14, 0),
      );

  static MovementEntity outboundFanta({int quantity = 3}) => MovementEntity(
        id: 'mov-out-002',
        tenantId: 'tenant-001',
        productId: 'prod-fanta-001',
        productName: 'Fanta Orange 1L',
        productSku: 'FA-OR-001',
        type: MovementType.outbound,
        quantity: quantity,
        unitPrice: 1200.0,
        createdAt: DateTime(2024, 6, 2, 10, 0),
      );

  static List<MovementEntity> get sampleSalesWeek => [
        outboundCoca(quantity: 10),
        outboundCoca(quantity: 5),
        outboundFanta(quantity: 8),
      ];
}
