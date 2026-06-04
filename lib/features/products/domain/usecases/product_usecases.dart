import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';

class WatchProductsUseCase {
  final ProductRepository repository;
  const WatchProductsUseCase(this.repository);

  Stream<Either<Failure, List<ProductEntity>>> call(String tenantId) =>
      repository.watchProducts(tenantId);
}

class WatchLowStockProductsUseCase {
  final ProductRepository repository;
  const WatchLowStockProductsUseCase(this.repository);

  Stream<Either<Failure, List<ProductEntity>>> call(String tenantId) =>
      repository.watchLowStockProducts(tenantId);
}

class GetProductUseCase {
  final ProductRepository repository;
  const GetProductUseCase(this.repository);

  Future<Either<Failure, ProductEntity>> call({
    required String tenantId,
    required String productId,
  }) =>
      repository.getProduct(tenantId: tenantId, productId: productId);
}

class CreateProductUseCase {
  final ProductRepository repository;
  const CreateProductUseCase(this.repository);

  Future<Either<Failure, ProductEntity>> call({
    required String tenantId,
    required ProductEntity product,
  }) =>
      repository.createProduct(tenantId: tenantId, product: product);
}

class UpdateProductUseCase {
  final ProductRepository repository;
  const UpdateProductUseCase(this.repository);

  Future<Either<Failure, ProductEntity>> call({
    required String tenantId,
    required ProductEntity product,
  }) =>
      repository.updateProduct(tenantId: tenantId, product: product);
}

class DeleteProductUseCase {
  final ProductRepository repository;
  const DeleteProductUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String tenantId,
    required String productId,
  }) =>
      repository.deleteProduct(tenantId: tenantId, productId: productId);
}
