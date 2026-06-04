import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';

void main() {
  group('CategoryEntity', () {
    final baseCategory = CategoryEntity(
      id: 'cat-001',
      tenantId: 'tenant-001',
      name: 'Boissons',
      description: 'Toutes les boissons',
      color: '#FF5722',
      createdAt: DateTime(2024, 1, 1),
    );

    // ── Instantiation ─────────────────────────────────────────────────────
    test('creates category with all required fields', () {
      expect(baseCategory.id, equals('cat-001'));
      expect(baseCategory.tenantId, equals('tenant-001'));
      expect(baseCategory.name, equals('Boissons'));
      expect(baseCategory.color, equals('#FF5722'));
    });

    test('description and color are nullable/optional', () {
      final c = CategoryEntity(
        id: 'cat-002',
        tenantId: 'tenant-001',
        name: 'Épicerie',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(c.description, isNull);
      expect(c.color, isNull);
    });

    // ── Equatable ─────────────────────────────────────────────────────────
    group('Equatable props', () {
      test('two categories with same id and tenantId are equal', () {
        final c1 = CategoryEntity(
          id: 'cat-001',
          tenantId: 'tenant-001',
          name: 'Nom original',
          createdAt: DateTime(2024, 1, 1),
        );
        final c2 = CategoryEntity(
          id: 'cat-001',
          tenantId: 'tenant-001',
          name: 'Nom modifié',
          description: 'desc',
          color: '#000000',
          createdAt: DateTime(2025, 1, 1),
        );
        expect(c1, equals(c2));
      });

      test('different tenant same id are not equal', () {
        final c1 = CategoryEntity(
          id: 'cat-001',
          tenantId: 'tenant-001',
          name: 'Boissons',
          createdAt: DateTime(2024, 1, 1),
        );
        final c2 = CategoryEntity(
          id: 'cat-001',
          tenantId: 'tenant-002',
          name: 'Boissons',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(c1, isNot(equals(c2)));
      });
    });

    // ── updatedAt ─────────────────────────────────────────────────────────
    test('updatedAt is initially null', () {
      expect(baseCategory.updatedAt, isNull);
    });
  });
}
