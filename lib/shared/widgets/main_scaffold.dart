import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_flutter/core/router/app_router.dart';
import 'package:stock_flutter/core/theme/app_theme.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.products)) return 1;
    if (location.startsWith(AppRoutes.categories)) return 2;
    if (location.startsWith(AppRoutes.movements)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final lowStockProducts = ref.watch(lowStockProductsProvider).valueOrNull ?? [];
    final lowStockCount = lowStockProducts.length;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.dashboard);
                break;
              case 1:
                context.go(AppRoutes.products);
                break;
              case 2:
                context.go(AppRoutes.categories);
                break;
              case 3:
                context.go(AppRoutes.movements);
                break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Produits',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category_rounded),
              label: 'Catégories',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: lowStockCount > 0,
                label: Text('$lowStockCount'),
                child: const Icon(Icons.swap_horiz_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: lowStockCount > 0,
                label: Text('$lowStockCount'),
                child: const Icon(Icons.swap_horiz_rounded),
              ),
              label: 'Mouvements',
            ),
          ],
        ),
      ),
    );
  }
}
