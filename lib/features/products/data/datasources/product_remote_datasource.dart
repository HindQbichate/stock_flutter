import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_flutter/core/constants/app_constants.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/products/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

abstract class ProductRemoteDataSource {
  Stream<List<ProductModel>> watchProducts(String tenantId);
  Stream<List<ProductModel>> watchLowStockProducts(String tenantId);
  Future<ProductModel> getProduct({required String tenantId, required String productId});
  Future<ProductModel> createProduct({required String tenantId, required ProductModel product});
  Future<ProductModel> updateProduct({required String tenantId, required ProductModel product});
  Future<void> deleteProduct({required String tenantId, required String productId});
  Stream<List<ProductModel>> watchProductsByCategory({
    required String tenantId,
    required String categoryId,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProductRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _productsRef(String tenantId) {
    return _firestore
        .collection(AppConstants.tenantsCollection)
        .doc(tenantId)
        .collection(AppConstants.productsCollection);
  }

  @override
  Stream<List<ProductModel>> watchProducts(String tenantId) {
    return _productsRef(tenantId)
        .orderBy(AppConstants.fieldName)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromFirestore(doc, tenantId))
            .toList());
  }

  @override
  Stream<List<ProductModel>> watchLowStockProducts(String tenantId) {
    return _productsRef(tenantId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromFirestore(doc, tenantId))
            .where((p) => p.quantity <= p.threshold)
            .toList());
  }

  @override
  Future<ProductModel> getProduct({
    required String tenantId,
    required String productId,
  }) async {
    final doc = await _productsRef(tenantId).doc(productId).get();
    if (!doc.exists) throw const NotFoundException();
    return ProductModel.fromFirestore(doc, tenantId);
  }

  @override
  Future<ProductModel> createProduct({
    required String tenantId,
    required ProductModel product,
  }) async {
    final id = const Uuid().v4();
    final newProduct = ProductModel(
      id: id,
      tenantId: tenantId,
      name: product.name,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      sku: product.sku.isNotEmpty ? product.sku : id.substring(0, 8).toUpperCase(),
      quantity: product.quantity,
      threshold: product.threshold,
      price: product.price,
      description: product.description,
      createdAt: DateTime.now(),
    );

    await _productsRef(tenantId).doc(id).set(newProduct.toFirestore());
    return newProduct;
  }

  @override
  Future<ProductModel> updateProduct({
    required String tenantId,
    required ProductModel product,
  }) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _productsRef(tenantId).doc(product.id).update(updated.toFirestore());
    return updated;
  }

  @override
  Future<void> deleteProduct({
    required String tenantId,
    required String productId,
  }) async {
    await _productsRef(tenantId).doc(productId).delete();
  }

  @override
  Stream<List<ProductModel>> watchProductsByCategory({
    required String tenantId,
    required String categoryId,
  }) {
    return _productsRef(tenantId)
        .where(AppConstants.fieldCategoryId, isEqualTo: categoryId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromFirestore(doc, tenantId))
            .toList());
  }
}
