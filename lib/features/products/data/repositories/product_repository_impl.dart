import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/data/datasources/product_remote_datasource.dart';
import 'package:stock_flutter/features/products/data/models/product_model.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  const ProductRepositoryImpl({required ProductRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchProducts(String tenantId) {
    return _remoteDataSource.watchProducts(tenantId).map(
          (products) => Right<Failure, List<ProductEntity>>(products),
        );
  }

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchLowStockProducts(String tenantId) {
    return _remoteDataSource.watchLowStockProducts(tenantId).map(
          (products) => Right<Failure, List<ProductEntity>>(products),
        );
  }

  @override
  Future<Either<Failure, ProductEntity>> getProduct({
    required String tenantId,
    required String productId,
  }) async {
    try {
      final product = await _remoteDataSource.getProduct(
        tenantId: tenantId,
        productId: productId,
      );
      return Right(product);
    } on NotFoundException {
      return const Left(NotFoundFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String tenantId,
    required ProductEntity product,
  }) async {
    try {
      final model = ProductModel(
        id: product.id,
        tenantId: product.tenantId,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        sku: product.sku,
        quantity: product.quantity,
        threshold: product.threshold,
        price: product.price,
        description: product.description,
        createdAt: product.createdAt,
      );
      final created = await _remoteDataSource.createProduct(
        tenantId: tenantId,
        product: model,
      );
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
    required String tenantId,
    required ProductEntity product,
  }) async {
    try {
      final model = ProductModel(
        id: product.id,
        tenantId: product.tenantId,
        name: product.name,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        sku: product.sku,
        quantity: product.quantity,
        threshold: product.threshold,
        price: product.price,
        description: product.description,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
      final updated = await _remoteDataSource.updateProduct(
        tenantId: tenantId,
        product: model,
      );
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct({
    required String tenantId,
    required String productId,
  }) async {
    try {
      await _remoteDataSource.deleteProduct(
        tenantId: tenantId,
        productId: productId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchProductsByCategory({
    required String tenantId,
    required String categoryId,
  }) {
    return _remoteDataSource
        .watchProductsByCategory(tenantId: tenantId, categoryId: categoryId)
        .map((products) => Right<Failure, List<ProductEntity>>(products));
  }
}
