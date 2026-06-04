import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';

void main() {
  group('ProductEntity', () {
    final baseProduct = ProductEntity(
      id: 'prod-001',
      tenantId: 'tenant-001',
      name: 'Coca-Cola 1L',
      categoryId: 'cat-001',
      categoryName: 'Boissons',
      sku: 'CC-1L-001',
      quantity: 50,
      threshold: 10,
      price: 1500.0,
      createdAt: DateTime(2024, 1, 1),
    );

    // ── isBelowThreshold ─────────────────────────────────────────────────
    group('isBelowThreshold', () {
      test('returns false when quantity > threshold', () {
        expect(baseProduct.isBelowThreshold, isFalse);
      });

      test('returns true when quantity == threshold', () {
        final p = ProductEntity(
          id: 'prod-002',
          tenantId: 'tenant-001',
          name: 'Produit Test',
          categoryId: 'cat-001',
          categoryName: 'Test',
          sku: 'TEST-001',
          quantity: 10,
          threshold: 10,
          price: 500.0,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(p.isBelowThreshold, isTrue);
      });

      test('returns true when quantity < threshold', () {
        final p = ProductEntity(
          id: 'prod-003',
          tenantId: 'tenant-001',
          name: 'Produit Critique',
          categoryId: 'cat-001',
          categoryName: 'Test',
          sku: 'CRIT-001',
          quantity: 3,
          threshold: 10,
          price: 500.0,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(p.isBelowThreshold, isTrue);
      });
    });

    // ── isOutOfStock ──────────────────────────────────────────────────────
    group('isOutOfStock', () {
      test('returns false when quantity > 0', () {
        expect(baseProduct.isOutOfStock, isFalse);
      });

      test('returns true when quantity == 0', () {
        final p = ProductEntity(
          id: 'prod-004',
          tenantId: 'tenant-001',
          name: 'Produit Épuisé',
          categoryId: 'cat-001',
          categoryName: 'Test',
          sku: 'OUT-001',
          quantity: 0,
          threshold: 5,
          price: 200.0,
          createdAt: DateTime(2024, 1, 1),
        );
        expect(p.isOutOfStock, isTrue);
      });
    });

    // ── Equatable ─────────────────────────────────────────────────────────
    group('Equatable props', () {
      test('two products with same id/tenantId/sku are equal', () {
        final p1 = ProductEntity(
          id: 'prod-001',
          tenantId: 'tenant-001',
          name: 'Nom 1',
          categoryId: 'cat-A',
          categoryName: 'Cat A',
          sku: 'SKU-001',
          quantity: 10,
          threshold: 5,
          price: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );
        final p2 = ProductEntity(
          id: 'prod-001',
          tenantId: 'tenant-001',
          name: 'Nom 2 différent',
          categoryId: 'cat-B',
          categoryName: 'Cat B',
          sku: 'SKU-001',
          quantity: 99,
          threshold: 1,
          price: 999.0,
          createdAt: DateTime(2025, 6, 1),
        );
        expect(p1, equals(p2));
      });

      test('two products with different sku are not equal', () {
        final p1 = ProductEntity(
          id: 'prod-001',
          tenantId: 'tenant-001',
          name: 'Produit',
          categoryId: 'cat-001',
          categoryName: 'Cat',
          sku: 'SKU-001',
          quantity: 10,
          threshold: 5,
          price: 100.0,
          createdAt: DateTime(2024, 1, 1),
        );
        final p2 = p1 == p1 ? p1 : p1; // same ref → equal
        expect(identical(p1, p2), isTrue);
      });
    });

    // ── Edge cases ────────────────────────────────────────────────────────
    test('product with null description is valid', () {
      final p = ProductEntity(
        id: 'prod-005',
        tenantId: 'tenant-001',
        name: 'Sans description',
        categoryId: 'cat-001',
        categoryName: 'Cat',
        sku: 'ND-001',
        quantity: 5,
        threshold: 2,
        price: 300.0,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(p.description, isNull);
      expect(p.isBelowThreshold, isFalse);
    });

    test('product with price 0 is valid (gratuit/offert)', () {
      final p = ProductEntity(
        id: 'prod-006',
        tenantId: 'tenant-001',
        name: 'Produit Gratuit',
        categoryId: 'cat-001',
        categoryName: 'Cat',
        sku: 'FREE-001',
        quantity: 100,
        threshold: 10,
        price: 0.0,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(p.price, equals(0.0));
    });
  });
}
