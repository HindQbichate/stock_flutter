import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_flutter/core/router/app_router.dart';
import 'package:stock_flutter/core/theme/app_theme.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final dateRange = ref.watch(dashboardDateRangeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (user != null)
              Text(
                user.displayName ?? user.email,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: [
          // Date range selector
          TextButton.icon(
            onPressed: () => _showDateRangePicker(context, ref, dateRange),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(
              '${DateFormat('dd/MM').format(dateRange.from)} - ${DateFormat('dd/MM').format(dateRange.to)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(movementsByDateRangeProvider),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    _KpiGrid(stats: stats),
                    const SizedBox(height: 24),

                    // Low stock alert
                    if (stats.lowStockCount > 0 || stats.outOfStockCount > 0)
                      _StockAlertBanner(
                        lowCount: stats.lowStockCount,
                        outCount: stats.outOfStockCount,
                        onTap: () => context.go(AppRoutes.products),
                      ),

                    if (stats.lowStockCount > 0 || stats.outOfStockCount > 0)
                      const SizedBox(height: 24),

                    // Top products
                    if (stats.topProducts.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Top produits vendus',
                        subtitle: _periodLabel(dateRange),
                      ),
                      const SizedBox(height: 12),
                      _TopProductsChart(stats: stats),
                      const SizedBox(height: 24),
                    ],

                    // Sales by category pie chart
                    if (stats.salesByCategory.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Ventes par catégorie',
                        subtitle: _periodLabel(dateRange),
                      ),
                      const SizedBox(height: 12),
                      _CategoryPieChart(stats: stats),
                      const SizedBox(height: 24),
                    ],

                    // Recent movements
                    if (stats.recentMovements.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Mouvements récents',
                        onAction: () => context.go(AppRoutes.movements),
                        actionLabel: 'Voir tout',
                      ),
                      const SizedBox(height: 12),
                      _RecentMovementsList(movements: stats.recentMovements),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  String _periodLabel(DateRange dr) {
    return '${DateFormat('dd MMM', 'fr').format(dr.from)} → ${DateFormat('dd MMM', 'fr').format(dr.to)}';
  }

  void _showDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    DateRange current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DateRangeSheet(
        current: current,
        onSelected: (range) =>
            ref.read(dashboardDateRangeProvider.notifier).state = range,
      ),
    );
  }
}

// ─── KPI Grid ──────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final DashboardStats stats;
  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_MA', symbol: 'DH');
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          label: 'Produits',
          value: '${stats.totalProducts}',
          icon: Icons.inventory_2_rounded,
          color: AppColors.primary,
        ),
        _KpiCard(
          label: 'Ventes (période)',
          value: fmt.format(stats.totalSalesAmount),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        _KpiCard(
          label: 'Sous seuil',
          value: '${stats.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        _KpiCard(
          label: 'Rupture de stock',
          value: '${stats.outOfStockCount}',
          icon: Icons.remove_shopping_cart_rounded,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

// ─── Top Products Bar Chart ────────────────────────────────────────────────
class _TopProductsChart extends StatelessWidget {
  final DashboardStats stats;
  const _TopProductsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.topProducts.isEmpty) return const SizedBox.shrink();

    final maxQty = stats.topProducts.map((p) => p.quantitySold).reduce(
          (a, b) => a > b ? a : b,
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxQty.toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= stats.topProducts.length) return const SizedBox();
                  final name = stats.topProducts[idx].productName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}…' : name,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            stats.topProducts.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats.topProducts[i].quantitySold.toDouble(),
                  color: AppColors.chartColors[i % AppColors.chartColors.length],
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// ─── Category Pie Chart ────────────────────────────────────────────────────
class _CategoryPieChart extends StatelessWidget {
  final DashboardStats stats;
  const _CategoryPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total =
        stats.salesByCategory.fold<double>(0, (s, c) => s + c.revenue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: PieChart(
              PieChartData(
                sections: List.generate(
                  stats.salesByCategory.length,
                  (i) {
                    final cat = stats.salesByCategory[i];
                    final pct = total > 0 ? (cat.revenue / total * 100) : 0;
                    return PieChartSectionData(
                      value: cat.revenue,
                      color: AppColors.chartColors[
                          i % AppColors.chartColors.length],
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 55,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                centerSpaceRadius: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                stats.salesByCategory.length,
                (i) {
                  final cat = stats.salesByCategory[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.chartColors[
                                i % AppColors.chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Movements List ─────────────────────────────────────────────────
class _RecentMovementsList extends StatelessWidget {
  final List<MovementEntity> movements;
  const _RecentMovementsList({required this.movements});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movements.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = movements[i];
          final isIn = m.type == MovementType.inbound;
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isIn ? AppColors.success : AppColors.error)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isIn ? AppColors.success : AppColors.error,
                size: 18,
              ),
            ),
            title: Text(m.productName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(m.createdAt),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '${isIn ? '+' : '-'}${m.quantity}',
              style: TextStyle(
                color: isIn ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Date Range Sheet ──────────────────────────────────────────────────────
class _DateRangeSheet extends StatelessWidget {
  final DateRange current;
  final void Function(DateRange) onSelected;

  const _DateRangeSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('7 derniers jours', DateRange.last7Days()),
      ('30 derniers jours', DateRange.last30Days()),
      ('Ce mois', DateRange.thisMonth()),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Période', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...presets.map(
            (p) => ListTile(
              title: Text(p.$1),
              onTap: () {
                onSelected(p.$2);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
