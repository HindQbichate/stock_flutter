import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flutter/core/errors/failures.dart';

void main() {
  group('Failures', () {
    // ── ServerFailure ─────────────────────────────────────────────────────
    group('ServerFailure', () {
      test('stores message correctly', () {
        const f = ServerFailure('Erreur réseau');
        expect(f.message, equals('Erreur réseau'));
      });

      test('two ServerFailures with same message are equal (Equatable)', () {
        const f1 = ServerFailure('Erreur');
        const f2 = ServerFailure('Erreur');
        expect(f1, equals(f2));
      });

      test('two ServerFailures with different message are not equal', () {
        const f1 = ServerFailure('Erreur A');
        const f2 = ServerFailure('Erreur B');
        expect(f1, isNot(equals(f2)));
      });
    });

    // ── AuthFailure ───────────────────────────────────────────────────────
    group('AuthFailure', () {
      test('stores message correctly', () {
        const f = AuthFailure('Email invalide');
        expect(f.message, equals('Email invalide'));
      });

      test('AuthFailure is a Failure', () {
        const f = AuthFailure('Erreur auth');
        expect(f, isA<Failure>());
      });
    });

    // ── InsufficientStockFailure ──────────────────────────────────────────
    group('InsufficientStockFailure', () {
      test('stores message and available quantity', () {
        const f = InsufficientStockFailure(
          'Stock insuffisant',
          availableQuantity: 3,
        );
        expect(f.message, equals('Stock insuffisant'));
        expect(f.availableQuantity, equals(3));
      });

      test('is a Failure', () {
        const f = InsufficientStockFailure('Stock insuf.', availableQuantity: 0);
        expect(f, isA<Failure>());
      });

      test('two identical InsufficientStockFailures are equal', () {
        const f1 = InsufficientStockFailure('msg', availableQuantity: 5);
        const f2 = InsufficientStockFailure('msg', availableQuantity: 5);
        expect(f1, equals(f2));
      });

      test('different availableQuantity makes them not equal', () {
        const f1 = InsufficientStockFailure('msg', availableQuantity: 3);
        const f2 = InsufficientStockFailure('msg', availableQuantity: 5);
        expect(f1, isNot(equals(f2)));
      });
    });

    // ── CacheFailure ──────────────────────────────────────────────────────
    group('CacheFailure', () {
      test('is a Failure', () {
        const f = CacheFailure('Cache corrompu');
        expect(f, isA<Failure>());
      });
    });

    // ── Different failure types are not equal ─────────────────────────────
    test('ServerFailure and AuthFailure with same message are not equal', () {
      const sf = ServerFailure('Erreur');
      const af = AuthFailure('Erreur');
      expect(sf, isNot(equals(af)));
    });
  });
}
