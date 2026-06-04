import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:stock_flutter/features/auth/presentation/pages/register_page.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:stock_flutter/features/products/presentation/pages/products_page.dart';
import 'package:stock_flutter/features/products/presentation/pages/product_form_page.dart';
import 'package:stock_flutter/features/products/presentation/pages/product_detail_page.dart';
import 'package:stock_flutter/features/categories/presentation/pages/categories_page.dart';
import 'package:stock_flutter/features/movements/presentation/pages/movements_page.dart';
import 'package:stock_flutter/features/movements/presentation/pages/stock_entry_page.dart';
import 'package:stock_flutter/features/movements/presentation/pages/stock_sale_page.dart';
import 'package:stock_flutter/shared/widgets/main_scaffold.dart';

// Route names
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String productForm = '/products/form';
  static const String productDetail = '/products/:id';
  static const String categories = '/categories';
  static const String movements = '/movements';
  static const String stockEntry = '/movements/entry';
  static const String stockSale = '/movements/sale';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!isAuthenticated && !isGoingToAuth) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isGoingToAuth) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // ── Main shell with bottom navigation ────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.products,
            name: 'products',
            builder: (context, state) => const ProductsPage(),
            routes: [
              GoRoute(
                path: 'form',
                name: 'productForm',
                builder: (context, state) {
                  final productId = state.uri.queryParameters['id'];
                  return ProductFormPage(productId: productId);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'productDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ProductDetailPage(productId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.categories,
            name: 'categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: AppRoutes.movements,
            name: 'movements',
            builder: (context, state) => const MovementsPage(),
            routes: [
              GoRoute(
                path: 'entry',
                name: 'stockEntry',
                builder: (context, state) => const StockEntryPage(),
              ),
              GoRoute(
                path: 'sale',
                name: 'stockSale',
                builder: (context, state) => const StockSalePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.uri}'),
      ),
    ),
  );
});
