// Manually written mock for ProductRepository
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {
  @override
  Stream<Either<Failure, List<ProductEntity>>> watchProducts(String tenantId) =>
      super.noSuchMethod(
        Invocation.method(#watchProducts, [tenantId]),
        returnValue: const Stream.empty(),
      ) as Stream<Either<Failure, List<ProductEntity>>>;

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchLowStockProducts(String tenantId) =>
      super.noSuchMethod(
        Invocation.method(#watchLowStockProducts, [tenantId]),
        returnValue: const Stream.empty(),
      ) as Stream<Either<Failure, List<ProductEntity>>>;

  @override
  Future<Either<Failure, ProductEntity>> getProduct({
    required String tenantId,
    required String productId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#getProduct, [], {#tenantId: tenantId, #productId: productId}),
        returnValue: Future.value(const Left(ServerFailure('mock'))),
      ) as Future<Either<Failure, ProductEntity>>;

  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String tenantId,
    required ProductEntity product,
  }) =>
      super.noSuchMethod(
        Invocation.method(#createProduct, [], {#tenantId: tenantId, #product: product}),
        returnValue: Future.value(const Left(ServerFailure('mock'))),
      ) as Future<Either<Failure, ProductEntity>>;

  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
    required String tenantId,
    required ProductEntity product,
  }) =>
      super.noSuchMethod(
        Invocation.method(#updateProduct, [], {#tenantId: tenantId, #product: product}),
        returnValue: Future.value(const Left(ServerFailure('mock'))),
      ) as Future<Either<Failure, ProductEntity>>;

  @override
  Future<Either<Failure, Unit>> deleteProduct({
    required String tenantId,
    required String productId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#deleteProduct, [], {#tenantId: tenantId, #productId: productId}),
        returnValue: Future.value(const Left(ServerFailure('mock'))),
      ) as Future<Either<Failure, Unit>>;

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchProductsByCategory({
    required String tenantId,
    required String categoryId,
  }) =>
      super.noSuchMethod(
        Invocation.method(#watchProductsByCategory, [], {
          #tenantId: tenantId,
          #categoryId: categoryId,
        }),
        returnValue: const Stream.empty(),
      ) as Stream<Either<Failure, List<ProductEntity>>>;
}
