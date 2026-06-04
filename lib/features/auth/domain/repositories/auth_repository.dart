import 'package:dartz/dartz.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Get current authenticated user
  UserEntity? get currentUser;

  /// Sign in with email and password
  Future<Either<AuthFailure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register a new user (creates tenant automatically)
  Future<Either<AuthFailure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out
  Future<Either<AuthFailure, Unit>> signOut();

  /// Send password reset email
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  });
}
