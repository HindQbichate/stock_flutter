import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/movements/data/models/movement_model.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';

// ─── Date Range State ──────────────────────────────────────────────────────
class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange({required this.from, required this.to});

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    return DateRange(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(
      from: now.subtract(const Duration(days: 7)),
      to: now,
    );
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
  }
}

final dashboardDateRangeProvider = StateProvider<DateRange>(
  (_) => DateRange.thisMonth(),
);

// ─── Dashboard Stats ───────────────────────────────────────────────────────
class DashboardStats {
  final int totalProducts;
  final int totalCategories;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalSalesAmount;
  final int totalSalesCount;
  final int totalEntriesCount;
  final List<TopProduct> topProducts;
  final List<CategorySales> salesByCategory;
  final List<MovementEntity> recentMovements;

  const DashboardStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalSalesAmount,
    required this.totalSalesCount,
    required this.totalEntriesCount,
    required this.topProducts,
    required this.salesByCategory,
    required this.recentMovements,
  });
}

class TopProduct {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });
}

class CategorySales {
  final String categoryId;
  final String categoryName;
  final int quantitySold;
  final double revenue;

  const CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.quantitySold,
    required this.revenue,
  });
}

// ─── Movements by date range ───────────────────────────────────────────────
final movementsByDateRangeProvider =
    StreamProvider<List<MovementEntity>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  final dateRange = ref.watch(dashboardDateRangeProvider);
  if (tenantId == null) return const Stream.empty();

  return ref
      .watch(movementDataSourceProvider)
      .watchMovementsByDateRange(
        tenantId: tenantId,
        from: dateRange.from,
        to: dateRange.to,
      );
});

// ─── Computed Dashboard Stats ──────────────────────────────────────────────
final dashboardStatsProvider = Provider<DashboardStats?>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull;
  final movements = ref.watch(movementsByDateRangeProvider).valueOrNull;

  if (products == null || movements == null) return null;

  final outboundMovements = movements
      .where((m) => m.type == MovementType.outbound)
      .toList();

  final inboundMovements = movements
      .where((m) => m.type == MovementType.inbound)
      .toList();

  // Sales stats
  final totalSalesAmount = outboundMovements.fold<double>(
    0,
    (sum, m) => sum + (m.unitPrice ?? 0) * m.quantity,
  );

  // Top products by quantity sold
  final Map<String, TopProduct> topMap = {};
  for (final m in outboundMovements) {
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

  final topProducts = topMap.values.toList()
    ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

  // Sales by category (from product data)
  final Map<String, CategorySales> catMap = {};
  for (final m in outboundMovements) {
    final product = products.firstWhere(
      (p) => p.id == m.productId,
      orElse: () => ProductEntity(
        id: '',
        tenantId: '',
        name: m.productName,
        categoryId: 'unknown',
        categoryName: 'Inconnu',
        sku: '',
        quantity: 0,
        threshold: 0,
        price: 0,
        createdAt: DateTime.now(),
      ),
    );
    final key = product.categoryId;
    if (catMap.containsKey(key)) {
      final existing = catMap[key]!;
      catMap[key] = CategorySales(
        categoryId: key,
        categoryName: product.categoryName,
        quantitySold: existing.quantitySold + m.quantity,
        revenue: existing.revenue + (m.unitPrice ?? 0) * m.quantity,
      );
    } else {
      catMap[key] = CategorySales(
        categoryId: key,
        categoryName: product.categoryName,
        quantitySold: m.quantity,
        revenue: (m.unitPrice ?? 0) * m.quantity,
      );
    }
  }

  return DashboardStats(
    totalProducts: products.length,
    totalCategories: products.map((p) => p.categoryId).toSet().length,
    lowStockCount: products.where((p) => p.isBelowThreshold && !p.isOutOfStock).length,
    outOfStockCount: products.where((p) => p.isOutOfStock).length,
    totalSalesAmount: totalSalesAmount,
    totalSalesCount: outboundMovements.length,
    totalEntriesCount: inboundMovements.length,
    topProducts: topProducts.take(5).toList(),
    salesByCategory: catMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue)),
    recentMovements: movements.take(10).toList(),
  );
});
