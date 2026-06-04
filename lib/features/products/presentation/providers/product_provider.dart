import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/products/data/datasources/product_remote_datasource.dart';
import 'package:stock_flutter/features/products/data/repositories/product_repository_impl.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';
import 'package:stock_flutter/features/products/domain/usecases/product_usecases.dart';

// ─── Data source ──────────────────────────────────────────────────────────
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

// ─── Repository ───────────────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
  );
});

// ─── Use Cases ────────────────────────────────────────────────────────────
final watchProductsUseCaseProvider = Provider(
  (ref) => WatchProductsUseCase(ref.watch(productRepositoryProvider)),
);

final watchLowStockUseCaseProvider = Provider(
  (ref) => WatchLowStockProductsUseCase(ref.watch(productRepositoryProvider)),
);

final createProductUseCaseProvider = Provider(
  (ref) => CreateProductUseCase(ref.watch(productRepositoryProvider)),
);

final updateProductUseCaseProvider = Provider(
  (ref) => UpdateProductUseCase(ref.watch(productRepositoryProvider)),
);

final deleteProductUseCaseProvider = Provider(
  (ref) => DeleteProductUseCase(ref.watch(productRepositoryProvider)),
);

// ─── Products Stream ──────────────────────────────────────────────────────
final productsStreamProvider = StreamProvider<List<ProductEntity>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return const Stream.empty();

  return ref
      .watch(watchProductsUseCaseProvider)
      .call(tenantId)
      .map((either) => either.getOrElse(() => []));
});

// ─── Low Stock Products Stream ────────────────────────────────────────────
final lowStockProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return const Stream.empty();

  return ref
      .watch(watchLowStockUseCaseProvider)
      .call(tenantId)
      .map((either) => either.getOrElse(() => []));
});

// ─── Product search filter ────────────────────────────────────────────────
final productSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<List<ProductEntity>>((ref) {
  final products = ref.watch(productsStreamProvider).valueOrNull ?? [];
  final query = ref.watch(productSearchQueryProvider).toLowerCase();

  if (query.isEmpty) return products;

  return products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.sku.toLowerCase().contains(query) ||
        p.categoryName.toLowerCase().contains(query);
  }).toList();
});

// ─── Product Notifier (CRUD actions) ─────────────────────────────────────
class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProductNotifier(this._ref) : super(const AsyncValue.data(null));

  String? get _tenantId => _ref.read(currentTenantIdProvider);

  Future<bool> createProduct(ProductEntity product) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = const AsyncValue.loading();
    final result = await _ref
        .read(createProductUseCaseProvider)
        .call(tenantId: tenantId, product: product);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> updateProduct(ProductEntity product) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = const AsyncValue.loading();
    final result = await _ref
        .read(updateProductUseCaseProvider)
        .call(tenantId: tenantId, product: product);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> deleteProduct(String productId) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = const AsyncValue.loading();
    final result = await _ref
        .read(deleteProductUseCaseProvider)
        .call(tenantId: tenantId, productId: productId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>(
  (ref) => ProductNotifier(ref),
);
