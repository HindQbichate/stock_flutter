import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';

/// Simulates the atomic stock movement transaction logic
/// (mirrors MovementDataSource.recordMovement)
Future<Map<String, dynamic>> simulateStockMovement({
  required FakeFirebaseFirestore firestore,
  required String tenantId,
  required String productId,
  required MovementType type,
  required int quantity,
  required double unitPrice,
}) async {
  final productRef = firestore
      .collection('tenants/$tenantId/products')
      .doc(productId);

  final productSnap = await productRef.get();
  if (!productSnap.exists) throw Exception('Produit introuvable');

  final currentQty = (productSnap.data()!['quantity'] as num).toInt();

  if (type == MovementType.outbound && currentQty < quantity) {
    throw Exception('Stock insuffisant: $currentQty disponible, $quantity demandé');
  }

  final newQty = type == MovementType.inbound
      ? currentQty + quantity
      : currentQty - quantity;

  // Write movement + update product
  final movRef = firestore.collection('tenants/$tenantId/movements').doc();
  await movRef.set({
    'productId': productId,
    'type': type == MovementType.inbound ? 'inbound' : 'outbound',
    'quantity': quantity,
    'unitPrice': unitPrice,
    'createdAt': DateTime.now(),
  });
  await productRef.update({'quantity': newQty});

  return {'movementId': movRef.id, 'newQuantity': newQty};
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  const tenantId = 'tenant-001';
  const productId = 'prod-001';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();

    // Seed a product
    await fakeFirestore
        .collection('tenants/$tenantId/products')
        .doc(productId)
        .set({
      'name': 'Coca-Cola 1L',
      'categoryId': 'cat-001',
      'categoryName': 'Boissons',
      'sku': 'CC-1L-001',
      'quantity': 50,
      'threshold': 10,
      'price': 1500.0,
      'createdAt': DateTime(2024, 1, 1),
    });
  });

  group('Stock Entry (inbound) flow', () {
    test('increases product quantity after inbound movement', () async {
      final result = await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.inbound,
        quantity: 20,
        unitPrice: 1200.0,
      );

      expect(result['newQuantity'], equals(70)); // 50 + 20

      // Verify movement was recorded
      final movements = await fakeFirestore
          .collection('tenants/$tenantId/movements')
          .get();
      expect(movements.docs.length, equals(1));
      expect(movements.docs.first['quantity'], equals(20));
      expect(movements.docs.first['type'], equals('inbound'));
    });

    test('creates movement document with correct unitPrice', () async {
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.inbound,
        quantity: 10,
        unitPrice: 900.0,
      );

      final movements = await fakeFirestore
          .collection('tenants/$tenantId/movements')
          .get();
      expect(movements.docs.first['unitPrice'], equals(900.0));
    });

    test('multiple consecutive entries accumulate correctly', () async {
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.inbound,
        quantity: 10,
        unitPrice: 900.0,
      );
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.inbound,
        quantity: 5,
        unitPrice: 900.0,
      );

      final productSnap = await fakeFirestore
          .collection('tenants/$tenantId/products')
          .doc(productId)
          .get();
      expect(productSnap['quantity'], equals(65)); // 50 + 10 + 5
    });
  });

  group('Stock Sale (outbound) flow', () {
    test('decreases product quantity after outbound movement', () async {
      final result = await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.outbound,
        quantity: 5,
        unitPrice: 1500.0,
      );

      expect(result['newQuantity'], equals(45)); // 50 - 5
    });

    test('throws exception when quantity exceeds stock', () async {
      await expectLater(
        simulateStockMovement(
          firestore: fakeFirestore,
          tenantId: tenantId,
          productId: productId,
          type: MovementType.outbound,
          quantity: 100, // more than available (50)
          unitPrice: 1500.0,
        ),
        throwsException,
      );
    });

    test('does not modify stock when sale fails due to insufficient stock', () async {
      try {
        await simulateStockMovement(
          firestore: fakeFirestore,
          tenantId: tenantId,
          productId: productId,
          type: MovementType.outbound,
          quantity: 100,
          unitPrice: 1500.0,
        );
      } catch (_) {}

      // Stock should remain unchanged
      final productSnap = await fakeFirestore
          .collection('tenants/$tenantId/products')
          .doc(productId)
          .get();
      expect(productSnap['quantity'], equals(50));
    });

    test('allows selling exact available quantity (boundary)', () async {
      final result = await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.outbound,
        quantity: 50, // exactly available
        unitPrice: 1500.0,
      );
      expect(result['newQuantity'], equals(0));
    });

    test('sequential entry then sale produces correct final stock', () async {
      // Entry +30
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.inbound,
        quantity: 30,
        unitPrice: 1200.0,
      );

      // Sale -25
      final result = await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: tenantId,
        productId: productId,
        type: MovementType.outbound,
        quantity: 25,
        unitPrice: 1500.0,
      );

      expect(result['newQuantity'], equals(55)); // 50 + 30 - 25

      // Verify 2 movement documents
      final movements = await fakeFirestore
          .collection('tenants/$tenantId/movements')
          .get();
      expect(movements.docs.length, equals(2));
    });
  });

  group('Multi-tenant isolation', () {
    test('products from different tenants are independent', () async {
      // Seed tenant-002 product
      await fakeFirestore
          .collection('tenants/tenant-002/products')
          .doc('prod-002')
          .set({
        'name': 'Produit Tenant 2',
        'categoryId': 'cat-001',
        'categoryName': 'Cat',
        'sku': 'T2-001',
        'quantity': 100,
        'threshold': 5,
        'price': 500.0,
        'createdAt': DateTime(2024, 1, 1),
      });

      // Movement on tenant-001 should NOT affect tenant-002
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: 'tenant-001',
        productId: productId,
        type: MovementType.outbound,
        quantity: 10,
        unitPrice: 1500.0,
      );

      final t1Product = await fakeFirestore
          .collection('tenants/tenant-001/products')
          .doc(productId)
          .get();
      final t2Product = await fakeFirestore
          .collection('tenants/tenant-002/products')
          .doc('prod-002')
          .get();

      expect(t1Product['quantity'], equals(40)); // 50 - 10
      expect(t2Product['quantity'], equals(100)); // unchanged
    });

    test('movements from tenant-001 are not visible in tenant-002', () async {
      await simulateStockMovement(
        firestore: fakeFirestore,
        tenantId: 'tenant-001',
        productId: productId,
        type: MovementType.inbound,
        quantity: 5,
        unitPrice: 1000.0,
      );

      final t2Movements = await fakeFirestore
          .collection('tenants/tenant-002/movements')
          .get();

      expect(t2Movements.docs, isEmpty);
    });
  });
}
