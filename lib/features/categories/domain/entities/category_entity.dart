import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tenantId, name];
}
