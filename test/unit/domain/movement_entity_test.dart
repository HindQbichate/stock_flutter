import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';

void main() {
  group('MovementEntity', () {
    final now = DateTime(2024, 6, 1, 10, 0);

    MovementEntity makeMovement({
      MovementType type = MovementType.outbound,
      int quantity = 5,
      double? unitPrice = 1500.0,
    }) =>
        MovementEntity(
          id: 'mov-001',
          tenantId: 'tenant-001',
          productId: 'prod-001',
          productName: 'Coca-Cola 1L',
          productSku: 'CC-1L-001',
          type: type,
          quantity: quantity,
          unitPrice: unitPrice,
          createdAt: now,
        );

    // ── isInbound / isOutbound ────────────────────────────────────────────
    group('type helpers', () {
      test('isInbound is true for inbound movement', () {
        final m = makeMovement(type: MovementType.inbound);
        expect(m.isInbound, isTrue);
        expect(m.isOutbound, isFalse);
      });

      test('isOutbound is true for outbound movement', () {
        final m = makeMovement(type: MovementType.outbound);
        expect(m.isOutbound, isTrue);
        expect(m.isInbound, isFalse);
      });
    });

    // ── totalValue ────────────────────────────────────────────────────────
    group('totalValue', () {
      test('computes correctly: unitPrice * quantity', () {
        final m = makeMovement(quantity: 5, unitPrice: 1500.0);
        expect(m.totalValue, equals(7500.0));
      });

      test('returns 0 when unitPrice is null', () {
        final m = makeMovement(unitPrice: null);
        expect(m.totalValue, equals(0.0));
      });

      test('returns 0 for quantity 0', () {
        final m = makeMovement(quantity: 0, unitPrice: 1500.0);
        expect(m.totalValue, equals(0.0));
      });

      test('handles large values without overflow', () {
        final m = makeMovement(quantity: 10000, unitPrice: 99999.99);
        expect(m.totalValue, closeTo(999999900.0, 0.01));
      });

      test('handles fractional unit price', () {
        final m = makeMovement(quantity: 3, unitPrice: 333.33);
        expect(m.totalValue, closeTo(999.99, 0.01));
      });
    });

    // ── Equatable props ───────────────────────────────────────────────────
    group('Equatable', () {
      test('same id/tenantId/productId/type/createdAt are equal', () {
        final m1 = MovementEntity(
          id: 'mov-001',
          tenantId: 'tenant-001',
          productId: 'prod-001',
          productName: 'Coca',
          productSku: 'CC-001',
          type: MovementType.outbound,
          quantity: 10,
          createdAt: now,
        );
        final m2 = MovementEntity(
          id: 'mov-001',
          tenantId: 'tenant-001',
          productId: 'prod-001',
          productName: 'Autre nom',
          productSku: 'CC-001',
          type: MovementType.outbound,
          quantity: 999,
          unitPrice: 12345.0,
          createdAt: now,
        );
        expect(m1, equals(m2));
      });

      test('different type makes movement not equal', () {
        final m1 = makeMovement(type: MovementType.inbound);
        final m2 = makeMovement(type: MovementType.outbound);
        expect(m1, isNot(equals(m2)));
      });
    });

    // ── Note optional ─────────────────────────────────────────────────────
    test('movement without note is valid', () {
      final m = MovementEntity(
        id: 'mov-002',
        tenantId: 'tenant-001',
        productId: 'prod-001',
        productName: 'Produit',
        productSku: 'SKU',
        type: MovementType.inbound,
        quantity: 20,
        createdAt: now,
      );
      expect(m.note, isNull);
      expect(m.totalValue, equals(0.0));
    });
  });
}
