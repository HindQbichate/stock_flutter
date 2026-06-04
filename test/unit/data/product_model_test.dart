import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/products/data/models/product_model.dart';

void main() {
  group('ProductModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    // ── fromFirestore ─────────────────────────────────────────────────────
    group('fromFirestore', () {
      test('maps all fields correctly from Firestore document', () async {
        final now = DateTime(2024, 6, 1, 12, 0);

        // Insert a document into fake Firestore
        await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-001')
            .set({
          'name': 'Coca-Cola 1L',
          'categoryId': 'cat-001',
          'categoryName': 'Boissons',
          'sku': 'CC-1L-001',
          'quantity': 50,
          'threshold': 10,
          'price': 1500.0,
          'description': 'Boisson gazeuse',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': null,
        });

        final doc = await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-001')
            .get();

        final model = ProductModel.fromFirestore(doc, 'tenant-001');

        expect(model.id, equals('prod-001'));
        expect(model.tenantId, equals('tenant-001'));
        expect(model.name, equals('Coca-Cola 1L'));
        expect(model.categoryId, equals('cat-001'));
        expect(model.categoryName, equals('Boissons'));
        expect(model.sku, equals('CC-1L-001'));
        expect(model.quantity, equals(50));
        expect(model.threshold, equals(10));
        expect(model.price, equals(1500.0));
        expect(model.description, equals('Boisson gazeuse'));
        expect(model.createdAt, equals(now));
        expect(model.updatedAt, isNull);
      });

      test('handles null description gracefully', () async {
        await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-002')
            .set({
          'name': 'Sans description',
          'categoryId': 'cat-001',
          'categoryName': 'Cat',
          'sku': 'ND-001',
          'quantity': 10,
          'threshold': 5,
          'price': 500.0,
          'description': null,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': null,
        });

        final doc = await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-002')
            .get();

        final model = ProductModel.fromFirestore(doc, 'tenant-001');
        expect(model.description, isNull);
      });

      test('parses numeric fields as correct types', () async {
        await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-003')
            .set({
          'name': 'Produit numérique',
          'categoryId': 'cat-001',
          'categoryName': 'Cat',
          'sku': 'NUM-001',
          'quantity': 100, // int stored as int
          'threshold': 20,
          'price': 99.99, // double
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': null,
        });

        final doc = await fakeFirestore
            .collection('tenants/tenant-001/products')
            .doc('prod-003')
            .get();

        final model = ProductModel.fromFirestore(doc, 'tenant-001');
        expect(model.quantity, isA<int>());
        expect(model.price, isA<double>());
        expect(model.price, closeTo(99.99, 0.001));
      });
    });

    // ── toFirestore ───────────────────────────────────────────────────────
    group('toFirestore', () {
      final testModel = ProductModel(
        id: 'prod-001',
        tenantId: 'tenant-001',
        name: 'Coca-Cola 1L',
        categoryId: 'cat-001',
        categoryName: 'Boissons',
        sku: 'CC-1L-001',
        quantity: 50,
        threshold: 10,
        price: 1500.0,
        description: 'Boisson',
        createdAt: DateTime(2024, 6, 1),
      );

      test('serializes all fields to Map', () {
        final map = testModel.toFirestore();

        expect(map['name'], equals('Coca-Cola 1L'));
        expect(map['categoryId'], equals('cat-001'));
        expect(map['categoryName'], equals('Boissons'));
        expect(map['sku'], equals('CC-1L-001'));
        expect(map['quantity'], equals(50));
        expect(map['threshold'], equals(10));
        expect(map['price'], equals(1500.0));
        expect(map['description'], equals('Boisson'));
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['updatedAt'], isNull);
      });

      test('does not include tenantId in the map (stored in path)', () {
        final map = testModel.toFirestore();
        expect(map.containsKey('tenantId'), isFalse);
      });

      test('does not include id in the map (Firestore document id)', () {
        final map = testModel.toFirestore();
        expect(map.containsKey('id'), isFalse);
      });
    });

    // ── copyWith ──────────────────────────────────────────────────────────
    group('copyWith', () {
      final original = ProductModel(
        id: 'prod-001',
        tenantId: 'tenant-001',
        name: 'Original',
        categoryId: 'cat-001',
        categoryName: 'Cat A',
        sku: 'ORIG-001',
        quantity: 20,
        threshold: 5,
        price: 1000.0,
        createdAt: DateTime(2024, 1, 1),
      );

      test('copies with new name only', () {
        final copy = original.copyWith(name: 'Modifié');
        expect(copy.name, equals('Modifié'));
        expect(copy.sku, equals('ORIG-001')); // unchanged
        expect(copy.id, equals('prod-001'));   // id preserved
      });

      test('copies with new quantity', () {
        final copy = original.copyWith(quantity: 100);
        expect(copy.quantity, equals(100));
        expect(copy.name, equals('Original')); // unchanged
      });

      test('original is not mutated', () {
        original.copyWith(name: 'Autre', quantity: 999);
        expect(original.name, equals('Original'));
        expect(original.quantity, equals(20));
      });

      test('copyWith preserves id and tenantId', () {
        final copy = original.copyWith(price: 2000.0);
        expect(copy.id, equals(original.id));
        expect(copy.tenantId, equals(original.tenantId));
      });
    });

    // ── Round-trip ────────────────────────────────────────────────────────
    test('toFirestore → fromFirestore round-trip preserves data', () async {
      final original = ProductModel(
        id: 'prod-rt-001',
        tenantId: 'tenant-001',
        name: 'Round-trip Test',
        categoryId: 'cat-rt',
        categoryName: 'Test',
        sku: 'RT-001',
        quantity: 42,
        threshold: 7,
        price: 777.77,
        description: 'Test round-trip',
        createdAt: DateTime(2024, 6, 1, 8, 0),
      );

      // Write to fake Firestore
      await fakeFirestore
          .collection('tenants/tenant-001/products')
          .doc('prod-rt-001')
          .set(original.toFirestore());

      // Read back
      final doc = await fakeFirestore
          .collection('tenants/tenant-001/products')
          .doc('prod-rt-001')
          .get();

      final restored = ProductModel.fromFirestore(doc, 'tenant-001');

      expect(restored.name, equals(original.name));
      expect(restored.quantity, equals(original.quantity));
      expect(restored.price, closeTo(original.price, 0.001));
      expect(restored.description, equals(original.description));
    });
  });
}
