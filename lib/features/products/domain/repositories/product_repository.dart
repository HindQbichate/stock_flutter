import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';

abstract class ProductRepository {
  /// Stream of all products for current tenant
  Stream<Either<Failure, List<ProductEntity>>> watchProducts(String tenantId);

  /// Get products below threshold
  Stream<Either<Failure, List<ProductEntity>>> watchLowStockProducts(String tenantId);

  /// Get single product by ID
  Future<Either<Failure, ProductEntity>> getProduct({
    required String tenantId,
    required String productId,
  });

  /// Create product
  Future<Either<Failure, ProductEntity>> createProduct({
    required String tenantId,
    required ProductEntity product,
  });

  /// Update product
  Future<Either<Failure, ProductEntity>> updateProduct({
    required String tenantId,
    required ProductEntity product,
  });

  /// Delete product
  Future<Either<Failure, Unit>> deleteProduct({
    required String tenantId,
    required String productId,
  });

  /// Get products by category
  Stream<Either<Failure, List<ProductEntity>>> watchProductsByCategory({
    required String tenantId,
    required String categoryId,
  });
}
