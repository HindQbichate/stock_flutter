import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_flutter/features/products/domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.tenantId,
    required super.name,
    required super.categoryId,
    required super.categoryName,
    required super.sku,
    required super.quantity,
    required super.threshold,
    required super.price,
    super.description,
    required super.createdAt,
    super.updatedAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc, String tenantId) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      tenantId: tenantId,
      name: data['name'] as String,
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String? ?? '',
      sku: data['sku'] as String,
      quantity: (data['quantity'] as num).toInt(),
      threshold: (data['threshold'] as num).toInt(),
      price: (data['price'] as num).toDouble(),
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sku': sku,
      'quantity': quantity,
      'threshold': threshold,
      'price': price,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? name,
    String? categoryId,
    String? categoryName,
    String? sku,
    int? quantity,
    int? threshold,
    double? price,
    String? description,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
