import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Stream<Either<Failure, List<CategoryEntity>>> watchCategories(String tenantId);
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String tenantId,
    required CategoryEntity category,
  });
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required String tenantId,
    required CategoryEntity category,
  });
  Future<Either<Failure, Unit>> deleteCategory({
    required String tenantId,
    required String categoryId,
  });
}
