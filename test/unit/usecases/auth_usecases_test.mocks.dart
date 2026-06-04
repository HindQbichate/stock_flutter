// Manually written mock for AuthRepository (replaces build_runner generated file)
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:stock_flutter/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges =>
      super.noSuchMethod(Invocation.getter(#authStateChanges),
          returnValue: const Stream.empty()) as Stream<UserEntity?>;

  @override
  UserEntity? get currentUser =>
      super.noSuchMethod(Invocation.getter(#currentUser)) as UserEntity?;

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) =>
      super.noSuchMethod(
        Invocation.method(#signInWithEmail, [], {
          #email: email,
          #password: password,
        }),
        returnValue: Future.value(const Left(AuthFailure('mock'))),
      ) as Future<Either<AuthFailure, UserEntity>>;

  @override
  Future<Either<AuthFailure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#registerWithEmail, [], {
          #email: email,
          #password: password,
          #displayName: displayName,
        }),
        returnValue: Future.value(const Left(AuthFailure('mock'))),
      ) as Future<Either<AuthFailure, UserEntity>>;

  @override
  Future<Either<AuthFailure, Unit>> signOut() =>
      super.noSuchMethod(
        Invocation.method(#signOut, []),
        returnValue: Future.value(const Left(AuthFailure('mock'))),
      ) as Future<Either<AuthFailure, Unit>>;

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  }) =>
      super.noSuchMethod(
        Invocation.method(#sendPasswordResetEmail, [], {#email: email}),
        returnValue: Future.value(const Left(AuthFailure('mock'))),
      ) as Future<Either<AuthFailure, Unit>>;
}
