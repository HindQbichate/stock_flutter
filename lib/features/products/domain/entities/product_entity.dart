import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String categoryId;
  final String categoryName;
  final String sku;
  final int quantity;
  final int threshold; // Seuil d'approvisionnement
  final double price;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.sku,
    required this.quantity,
    required this.threshold,
    required this.price,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isBelowThreshold => quantity <= threshold;
  bool get isOutOfStock => quantity == 0;

  @override
  List<Object?> get props => [id, tenantId, sku];
}
