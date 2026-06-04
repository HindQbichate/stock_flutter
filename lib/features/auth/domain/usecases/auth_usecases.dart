import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/domain/entities/user_entity.dart';
import 'package:stock_flutter/features/auth/domain/repositories/auth_repository.dart';

// ─── Sign In Use Case ──────────────────────────────────────────────────────
class SignInUseCase {
  final AuthRepository repository;
  const SignInUseCase(this.repository);

  Future<Either<AuthFailure, UserEntity>> call({
    required String email,
    required String password,
  }) =>
      repository.signInWithEmail(email: email, password: password);
}

// ─── Register Use Case ─────────────────────────────────────────────────────
class RegisterUseCase {
  final AuthRepository repository;
  const RegisterUseCase(this.repository);

  Future<Either<AuthFailure, UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      repository.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
}

// ─── Sign Out Use Case ─────────────────────────────────────────────────────
class SignOutUseCase {
  final AuthRepository repository;
  const SignOutUseCase(this.repository);

  Future<Either<AuthFailure, Unit>> call() => repository.signOut();
}

// ─── Password Reset Use Case ───────────────────────────────────────────────
class SendPasswordResetUseCase {
  final AuthRepository repository;
  const SendPasswordResetUseCase(this.repository);

  Future<Either<AuthFailure, Unit>> call({required String email}) =>
      repository.sendPasswordResetEmail(email: email);
}
