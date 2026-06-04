import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';
import 'package:stock_flutter/features/products/domain/usecases/product_usecases.dart';

import 'product_usecases_test.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late CreateProductUseCase createUseCase;
  late UpdateProductUseCase updateUseCase;
  late DeleteProductUseCase deleteUseCase;
  late WatchProductsUseCase watchUseCase;

  const tenantId = 'tenant-001';

  final testProduct = ProductEntity(
    id: 'prod-001',
    tenantId: tenantId,
    name: 'Coca-Cola 1L',
    categoryId: 'cat-001',
    categoryName: 'Boissons',
    sku: 'CC-1L-001',
    quantity: 50,
    threshold: 10,
    price: 1500.0,
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockRepo = MockProductRepository();
    createUseCase = CreateProductUseCase(mockRepo);
    updateUseCase = UpdateProductUseCase(mockRepo);
    deleteUseCase = DeleteProductUseCase(mockRepo);
    watchUseCase = WatchProductsUseCase(mockRepo);
  });

  // ── CreateProductUseCase ──────────────────────────────────────────────
  group('CreateProductUseCase', () {
    test('returns created product on success', () async {
      when(mockRepo.createProduct(tenantId: tenantId, product: testProduct))
          .thenAnswer((_) async => Right(testProduct));

      final result = await createUseCase(tenantId: tenantId, product: testProduct);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (p) => expect(p.name, equals('Coca-Cola 1L')),
      );
      verify(mockRepo.createProduct(tenantId: tenantId, product: testProduct)).called(1);
    });

    test('returns ServerFailure on network error', () async {
      when(mockRepo.createProduct(tenantId: anyNamed('tenantId'), product: anyNamed('product')))
          .thenAnswer((_) async => const Left(ServerFailure('Erreur serveur')));

      final result = await createUseCase(tenantId: tenantId, product: testProduct);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should be failure'),
      );
    });

    test('calls repository exactly once', () async {
      when(mockRepo.createProduct(tenantId: anyNamed('tenantId'), product: anyNamed('product')))
          .thenAnswer((_) async => Right(testProduct));

      await createUseCase(tenantId: tenantId, product: testProduct);

      verify(mockRepo.createProduct(
        tenantId: anyNamed('tenantId'),
        product: anyNamed('product'),
      )).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });

  // ── UpdateProductUseCase ──────────────────────────────────────────────
  group('UpdateProductUseCase', () {
    test('returns updated product on success', () async {
      final updatedProduct = ProductEntity(
        id: 'prod-001',
        tenantId: tenantId,
        name: 'Coca-Cola 2L',
        categoryId: 'cat-001',
        categoryName: 'Boissons',
        sku: 'CC-2L-001',
        quantity: 30,
        threshold: 10,
        price: 2000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 6, 1),
      );

      when(mockRepo.updateProduct(tenantId: tenantId, product: updatedProduct))
          .thenAnswer((_) async => Right(updatedProduct));

      final result = await updateUseCase(tenantId: tenantId, product: updatedProduct);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (p) => expect(p.price, equals(2000.0)),
      );
    });

    test('returns Failure if product not found', () async {
      when(mockRepo.updateProduct(tenantId: anyNamed('tenantId'), product: anyNamed('product')))
          .thenAnswer((_) async => const Left(ServerFailure('Produit introuvable')));

      final result = await updateUseCase(tenantId: tenantId, product: testProduct);
      expect(result.isLeft(), isTrue);
    });
  });

  // ── DeleteProductUseCase ──────────────────────────────────────────────
  group('DeleteProductUseCase', () {
    test('returns Unit on successful delete', () async {
      when(mockRepo.deleteProduct(tenantId: tenantId, productId: 'prod-001'))
          .thenAnswer((_) async => const Right(unit));

      final result = await deleteUseCase(tenantId: tenantId, productId: 'prod-001');

      expect(result, equals(const Right(unit)));
      verify(mockRepo.deleteProduct(tenantId: tenantId, productId: 'prod-001')).called(1);
    });

    test('returns ServerFailure on delete error', () async {
      when(mockRepo.deleteProduct(
        tenantId: anyNamed('tenantId'),
        productId: anyNamed('productId'),
      )).thenAnswer((_) async => const Left(ServerFailure('Suppression impossible')));

      final result = await deleteUseCase(tenantId: tenantId, productId: 'prod-001');
      expect(result.isLeft(), isTrue);
    });
  });

  // ── WatchProductsUseCase ──────────────────────────────────────────────
  group('WatchProductsUseCase', () {
    test('returns stream of products for tenant', () {
      when(mockRepo.watchProducts(tenantId))
          .thenAnswer((_) => Stream.value(Right([testProduct])));

      final stream = watchUseCase(tenantId);

      expect(stream, emits(Right<Failure, List<ProductEntity>>([testProduct])));
    });

    test('returns empty stream when tenant has no products', () {
      when(mockRepo.watchProducts('tenant-empty'))
          .thenAnswer((_) => Stream.value(const Right([])));

      final stream = watchUseCase('tenant-empty');

      expect(stream, emits(const Right<Failure, List<ProductEntity>>([])));
    });
  });
}
