import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────
// Failures (Domain layer — retournés aux use cases)
// ─────────────────────────────────────────

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Pas de connexion internet'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Ressource introuvable'});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Accès refusé'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache local'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure({required super.message});
}

// ─────────────────────────────────────────
// Exceptions (Data layer)
// ─────────────────────────────────────────

class ServerException implements Exception {
  final String message;
  const ServerException({required this.message});
}

class NetworkException implements Exception {
  const NetworkException();
}

class AuthException implements Exception {
  final String message;
  const AuthException({required this.message});
}

class NotFoundException implements Exception {
  const NotFoundException();
}

class InsufficientStockException implements Exception {
  final String message;
  const InsufficientStockException({required this.message});
}
