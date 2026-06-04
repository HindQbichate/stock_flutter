import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/categories/data/models/category_model.dart';
import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';
import 'package:stock_flutter/features/categories/domain/repositories/category_repository.dart';

// ─── Repository Implementation ─────────────────────────────────────────────
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  const CategoryRepositoryImpl({required CategoryRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Stream<Either<Failure, List<CategoryEntity>>> watchCategories(String tenantId) {
    return _dataSource
        .watchCategories(tenantId)
        .map((cats) => Right<Failure, List<CategoryEntity>>(cats));
  }

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String tenantId,
    required CategoryEntity category,
  }) async {
    try {
      final model = CategoryModel(
        id: category.id,
        tenantId: tenantId,
        name: category.name,
        description: category.description,
        color: category.color,
        createdAt: category.createdAt,
      );
      final created = await _dataSource.createCategory(
        tenantId: tenantId,
        category: model,
      );
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required String tenantId,
    required CategoryEntity category,
  }) async {
    try {
      final model = CategoryModel(
        id: category.id,
        tenantId: tenantId,
        name: category.name,
        description: category.description,
        color: category.color,
        createdAt: category.createdAt,
      );
      final updated = await _dataSource.updateCategory(
        tenantId: tenantId,
        category: model,
      );
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory({
    required String tenantId,
    required String categoryId,
  }) async {
    try {
      await _dataSource.deleteCategory(
        tenantId: tenantId,
        categoryId: categoryId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────
final categoryDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    dataSource: ref.watch(categoryDataSourceProvider),
  );
});

final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return const Stream.empty();

  return ref
      .watch(categoryRepositoryProvider)
      .watchCategories(tenantId)
      .map((either) => either.getOrElse(() => []));
});

// ─── Category Notifier ─────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  CategoryNotifier(this._ref) : super(const AsyncValue.data(null));

  String? get _tenantId => _ref.read(currentTenantIdProvider);

  Future<CategoryEntity?> createCategory({
    required String name,
    String? description,
    String? color,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return null;

    state = const AsyncValue.loading();
    final category = CategoryModel(
      id: '',
      tenantId: tenantId,
      name: name,
      description: description,
      color: color,
      createdAt: DateTime.now(),
    );

    final result = await _ref
        .read(categoryRepositoryProvider)
        .createCategory(tenantId: tenantId, category: category);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (created) {
        state = const AsyncValue.data(null);
        return created;
      },
    );
  }

  Future<bool> deleteCategory(String categoryId) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = const AsyncValue.loading();
    final result = await _ref
        .read(categoryRepositoryProvider)
        .deleteCategory(tenantId: tenantId, categoryId: categoryId);

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

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>(
  (ref) => CategoryNotifier(ref),
);
