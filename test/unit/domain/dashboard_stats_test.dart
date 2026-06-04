import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';

// Helper to build a product
ProductEntity makeProduct({
  required String id,
  required String categoryId,
  required String categoryName,
  int quantity = 50,
  int threshold = 10,
}) =>
    ProductEntity(
      id: id,
      tenantId: 'tenant-001',
      name: 'Produit $id',
      categoryId: categoryId,
      categoryName: categoryName,
      sku: 'SKU-$id',
      quantity: quantity,
      threshold: threshold,
      price: 1000.0,
      createdAt: DateTime(2024, 1, 1),
    );

// Helper to build a movement
MovementEntity makeMovement({
  required String id,
  required String productId,
  required String productName,
  MovementType type = MovementType.outbound,
  int quantity = 5,
  double unitPrice = 1000.0,
  String categoryId = 'cat-001',
}) =>
    MovementEntity(
      id: id,
      tenantId: 'tenant-001',
      productId: productId,
      productName: productName,
      productSku: 'SKU-$productId',
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      createdAt: DateTime(2024, 6, 1),
    );

void main() {
  group('DashboardStats computation', () {
    // ── Stock counts ───────────────────────────────────────────────────────
    group('stock status counts', () {
      test('counts low stock products correctly', () {
        final products = [
          makeProduct(id: 'p1', categoryId: 'cat-001', categoryName: 'Cat A', quantity: 5, threshold: 10),  // below
          makeProduct(id: 'p2', categoryId: 'cat-001', categoryName: 'Cat A', quantity: 15, threshold: 10), // ok
          makeProduct(id: 'p3', categoryId: 'cat-001', categoryName: 'Cat A', quantity: 0, threshold: 5),   // out of stock (not below)
          makeProduct(id: 'p4', categoryId: 'cat-002', categoryName: 'Cat B', quantity: 10, threshold: 10), // exactly at threshold = below
        ];

        final lowStock = products.where((p) => p.isBelowThreshold && !p.isOutOfStock).length;
        expect(lowStock, equals(2)); // p1 and p4
      });

      test('counts out of stock products correctly', () {
        final products = [
          makeProduct(id: 'p1', categoryId: 'cat-001', categoryName: 'Cat', quantity: 0, threshold: 5),
          makeProduct(id: 'p2', categoryId: 'cat-001', categoryName: 'Cat', quantity: 0, threshold: 5),
          makeProduct(id: 'p3', categoryId: 'cat-001', categoryName: 'Cat', quantity: 10, threshold: 5),
        ];

        final outOfStock = products.where((p) => p.isOutOfStock).length;
        expect(outOfStock, equals(2));
      });

      test('counts unique categories from products', () {
        final products = [
          makeProduct(id: 'p1', categoryId: 'cat-001', categoryName: 'Boissons'),
          makeProduct(id: 'p2', categoryId: 'cat-001', categoryName: 'Boissons'),
          makeProduct(id: 'p3', categoryId: 'cat-002', categoryName: 'Épicerie'),
          makeProduct(id: 'p4', categoryId: 'cat-003', categoryName: 'Hygiène'),
        ];

        final categoryCount = products.map((p) => p.categoryId).toSet().length;
        expect(categoryCount, equals(3));
      });
    });

    // ── Sales stats ───────────────────────────────────────────────────────
    group('sales statistics', () {
      test('totalSalesAmount sums outbound movements only', () {
        final movements = [
          makeMovement(id: 'm1', productId: 'p1', productName: 'P1', type: MovementType.outbound, quantity: 3, unitPrice: 1000.0),
          makeMovement(id: 'm2', productId: 'p2', productName: 'P2', type: MovementType.outbound, quantity: 2, unitPrice: 500.0),
          makeMovement(id: 'm3', productId: 'p3', productName: 'P3', type: MovementType.inbound, quantity: 10, unitPrice: 800.0), // should NOT count
        ];

        final outbound = movements.where((m) => m.type == MovementType.outbound);
        final totalSales = outbound.fold<double>(0, (sum, m) => sum + (m.unitPrice ?? 0) * m.quantity);

        expect(totalSales, equals(4000.0)); // 3*1000 + 2*500
      });

      test('returns 0 sales when no outbound movements', () {
        final movements = [
          makeMovement(id: 'm1', productId: 'p1', productName: 'P1', type: MovementType.inbound, quantity: 20),
        ];

        final outbound = movements.where((m) => m.type == MovementType.outbound);
        final totalSales = outbound.fold<double>(0, (sum, m) => sum + (m.unitPrice ?? 0) * m.quantity);

        expect(totalSales, equals(0.0));
      });
    });

    // ── Top products ──────────────────────────────────────────────────────
    group('top products by quantity sold', () {
      test('aggregates multiple movements for same product', () {
        final movements = [
          makeMovement(id: 'm1', productId: 'p1', productName: 'Coca', quantity: 10, unitPrice: 1500.0),
          makeMovement(id: 'm2', productId: 'p1', productName: 'Coca', quantity: 5, unitPrice: 1500.0),
          makeMovement(id: 'm3', productId: 'p2', productName: 'Fanta', quantity: 3, unitPrice: 1200.0),
        ];

        final Map<String, TopProduct> topMap = {};
        for (final m in movements.where((m) => m.type == MovementType.outbound)) {
          if (topMap.containsKey(m.productId)) {
            final existing = topMap[m.productId]!;
            topMap[m.productId] = TopProduct(
              productId: m.productId,
              productName: m.productName,
              quantitySold: existing.quantitySold + m.quantity,
              revenue: existing.revenue + (m.unitPrice ?? 0) * m.quantity,
            );
          } else {
            topMap[m.productId] = TopProduct(
              productId: m.productId,
              productName: m.productName,
              quantitySold: m.quantity,
              revenue: (m.unitPrice ?? 0) * m.quantity,
            );
          }
        }

        expect(topMap['p1']!.quantitySold, equals(15)); // 10+5
        expect(topMap['p1']!.revenue, equals(22500.0));  // 15*1500
        expect(topMap['p2']!.quantitySold, equals(3));
      });

      test('sorts top products by quantitySold descending', () {
        final topProducts = [
          const TopProduct(productId: 'p1', productName: 'P1', quantitySold: 5, revenue: 5000),
          const TopProduct(productId: 'p2', productName: 'P2', quantitySold: 20, revenue: 24000),
          const TopProduct(productId: 'p3', productName: 'P3', quantitySold: 12, revenue: 14400),
        ]..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

        expect(topProducts.first.productName, equals('P2'));
        expect(topProducts.last.productName, equals('P1'));
      });

      test('limits top products to 5', () {
        final products = List.generate(
          10,
          (i) => TopProduct(
            productId: 'p$i',
            productName: 'Produit $i',
            quantitySold: 10 - i,
            revenue: (10 - i) * 1000.0,
          ),
        );

        final top5 = products.take(5).toList();
        expect(top5.length, equals(5));
      });
    });

    // ── DateRange factories ───────────────────────────────────────────────
    group('DateRange factories', () {
      test('thisMonth starts on day 1', () {
        final range = DateRange.thisMonth();
        expect(range.from.day, equals(1));
        expect(range.from.hour, equals(0));
      });

      test('last7Days spans exactly 7 days', () {
        final range = DateRange.last7Days();
        final diff = range.to.difference(range.from).inDays;
        expect(diff, equals(7));
      });

      test('last30Days spans exactly 30 days', () {
        final range = DateRange.last30Days();
        final diff = range.to.difference(range.from).inDays;
        expect(diff, equals(30));
      });

      test('last7Days.to is after last7Days.from', () {
        final range = DateRange.last7Days();
        expect(range.to.isAfter(range.from), isTrue);
      });
    });
  });
}
