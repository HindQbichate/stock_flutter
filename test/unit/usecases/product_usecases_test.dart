import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';
import 'package:stock_flutter/features/products/domain/repositories/product_repository.dart';
import 'package:stock_flutter/features/products/domain/usecases/product_usecases.dart';

@GenerateMocks([ProductRepository])
import 'product_usecases_test.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late CreateProductUseCase createUseCase;
  late UpdateProductUseCase updateUseCase;
  late DeleteProductUseCase deleteUseCase;

  final testProduct = ProductEntity(
    id: 'prod-001',
    tenantId: 'tenant-001',
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
  });

  // ── CreateProductUseCase ──────────────────────────────────────────────
  group('CreateProductUseCase', () {
    test('returns created product on success', () async {
      when(mockRepo.createProduct(any))
          .thenAnswer((_) async => Right(testProduct));

      final result = await createUseCase(testProduct);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (p) => expect(p.name, equals('Coca-Cola 1L')),
      );
      verify(mockRepo.createProduct(any)).called(1);
    });

    test('returns ServerFailure on network error', () async {
      const failure = ServerFailure('Erreur serveur');
      when(mockRepo.createProduct(any))
          .thenAnswer((_) async => const Left(failure));

      final result = await createUseCase(testProduct);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should be failure'),
      );
    });
  });

  // ── UpdateProductUseCase ──────────────────────────────────────────────
  group('UpdateProductUseCase', () {
    test('returns updated product on success', () async {
      final updatedProduct = ProductEntity(
        id: 'prod-001',
        tenantId: 'tenant-001',
        name: 'Coca-Cola 2L', // name changed
        categoryId: 'cat-001',
        categoryName: 'Boissons',
        sku: 'CC-2L-001',
        quantity: 30,
        threshold: 10,
        price: 2000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 6, 1),
      );

      when(mockRepo.updateProduct(any))
          .thenAnswer((_) async => Right(updatedProduct));

      final result = await updateUseCase(updatedProduct);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (p) => expect(p.price, equals(2000.0)),
      );
    });

    test('returns Failure if product not found', () async {
      const failure = ServerFailure('Produit introuvable');
      when(mockRepo.updateProduct(any))
          .thenAnswer((_) async => const Left(failure));

      final result = await updateUseCase(testProduct);
      expect(result.isLeft(), isTrue);
    });
  });

  // ── DeleteProductUseCase ──────────────────────────────────────────────
  group('DeleteProductUseCase', () {
    test('returns Unit on successful delete', () async {
      when(mockRepo.deleteProduct(
        productId: anyNamed('productId'),
        tenantId: anyNamed('tenantId'),
      )).thenAnswer((_) async => const Right(unit));

      final result = await deleteUseCase(
        productId: 'prod-001',
        tenantId: 'tenant-001',
      );

      expect(result, equals(const Right(unit)));
      verify(mockRepo.deleteProduct(
        productId: 'prod-001',
        tenantId: 'tenant-001',
      )).called(1);
    });

    test('returns ServerFailure on delete error', () async {
      const failure = ServerFailure('Suppression impossible');
      when(mockRepo.deleteProduct(
        productId: anyNamed('productId'),
        tenantId: anyNamed('tenantId'),
      )).thenAnswer((_) async => const Left(failure));

      final result = await deleteUseCase(
        productId: 'prod-001',
        tenantId: 'tenant-001',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // ── WatchProductsUseCase ──────────────────────────────────────────────
  group('WatchProductsUseCase', () {
    late WatchProductsUseCase watchUseCase;

    setUp(() => watchUseCase = WatchProductsUseCase(mockRepo));

    test('returns stream of products for tenant', () {
      when(mockRepo.watchProducts(tenantId: 'tenant-001'))
          .thenAnswer((_) => Stream.value([testProduct]));

      final stream = watchUseCase(tenantId: 'tenant-001');

      expect(stream, emits([testProduct]));
    });

    test('returns empty stream when tenant has no products', () {
      when(mockRepo.watchProducts(tenantId: 'tenant-empty'))
          .thenAnswer((_) => Stream.value([]));

      final stream = watchUseCase(tenantId: 'tenant-empty');

      expect(stream, emits(isEmpty));
    });
  });
}
