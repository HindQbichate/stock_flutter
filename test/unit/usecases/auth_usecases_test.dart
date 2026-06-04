import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:stock_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:stock_flutter/features/auth/domain/usecases/auth_usecases.dart';

import 'auth_usecases_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late SignInUseCase signInUseCase;
  late RegisterUseCase registerUseCase;
  late SignOutUseCase signOutUseCase;
  late SendPasswordResetUseCase resetUseCase;

  final testUser = UserEntity(
    uid: 'uid-001',
    email: 'test@example.com',
    displayName: 'Test User',
    tenantId: 'tenant-001',
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    signInUseCase = SignInUseCase(mockRepo);
    registerUseCase = RegisterUseCase(mockRepo);
    signOutUseCase = SignOutUseCase(mockRepo);
    resetUseCase = SendPasswordResetUseCase(mockRepo);
  });

  // ── SignInUseCase ─────────────────────────────────────────────────────
  group('SignInUseCase', () {
    test('returns UserEntity on success', () async {
      when(mockRepo.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => Right(testUser));

      final result = await signInUseCase(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, equals(Right(testUser)));
      verify(mockRepo.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('returns AuthFailure on wrong credentials', () async {
      const failure = AuthFailure('Identifiants incorrects');
      when(mockRepo.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(failure));

      final result = await signInUseCase(
        email: 'wrong@email.com',
        password: 'bad-pass',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Should have been a failure'),
      );
    });

    test('calls repository exactly once', () async {
      when(mockRepo.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(testUser));

      await signInUseCase(email: 'a@b.com', password: '123456');

      verify(mockRepo.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).called(1);
      verifyNoMoreInteractions(mockRepo);
    });
  });

  // ── RegisterUseCase ───────────────────────────────────────────────────
  group('RegisterUseCase', () {
    test('returns UserEntity on successful registration', () async {
      when(mockRepo.registerWithEmail(
        email: 'new@example.com',
        password: 'securePass1',
        displayName: 'Nouveau User',
      )).thenAnswer((_) async => Right(testUser));

      final result = await registerUseCase(
        email: 'new@example.com',
        password: 'securePass1',
        displayName: 'Nouveau User',
      );

      expect(result.isRight(), isTrue);
    });

    test('returns AuthFailure when email already in use', () async {
      const failure = AuthFailure('Cet email est déjà utilisé');
      when(mockRepo.registerWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
        displayName: anyNamed('displayName'),
      )).thenAnswer((_) async => const Left(failure));

      final result = await registerUseCase(
        email: 'existing@example.com',
        password: 'pass',
        displayName: 'User',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  // ── SignOutUseCase ────────────────────────────────────────────────────
  group('SignOutUseCase', () {
    test('returns Unit on successful sign out', () async {
      when(mockRepo.signOut()).thenAnswer((_) async => const Right(unit));

      final result = await signOutUseCase();

      expect(result, equals(const Right(unit)));
      verify(mockRepo.signOut()).called(1);
    });

    test('returns AuthFailure if sign out fails', () async {
      const failure = AuthFailure('Erreur lors de la déconnexion');
      when(mockRepo.signOut()).thenAnswer((_) async => const Left(failure));

      final result = await signOutUseCase();
      expect(result.isLeft(), isTrue);
    });
  });

  // ── SendPasswordResetUseCase ──────────────────────────────────────────
  group('SendPasswordResetUseCase', () {
    test('returns Unit when email is sent successfully', () async {
      when(mockRepo.sendPasswordResetEmail(email: 'test@example.com'))
          .thenAnswer((_) async => const Right(unit));

      final result = await resetUseCase(email: 'test@example.com');
      expect(result.isRight(), isTrue);
    });

    test('returns AuthFailure for unknown email', () async {
      const failure = AuthFailure('Email non trouvé');
      when(mockRepo.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async => const Left(failure));

      final result = await resetUseCase(email: 'unknown@example.com');
      expect(result.isLeft(), isTrue);
    });
  });
}
