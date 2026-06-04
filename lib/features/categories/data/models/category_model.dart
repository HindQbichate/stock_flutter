import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_flutter/core/constants/app_constants.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/categories/domain/entities/category_entity.dart';
import 'package:uuid/uuid.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.tenantId,
    required super.name,
    super.description,
    super.color,
    required super.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc, String tenantId) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      tenantId: tenantId,
      name: data['name'] as String,
      description: data['description'] as String?,
      color: data['color'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'color': color,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── DataSource ────────────────────────────────────────────────────────────
class CategoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  CategoryRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _ref(String tenantId) {
    return _firestore
        .collection(AppConstants.tenantsCollection)
        .doc(tenantId)
        .collection(AppConstants.categoriesCollection);
  }

  Stream<List<CategoryModel>> watchCategories(String tenantId) {
    return _ref(tenantId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CategoryModel.fromFirestore(doc, tenantId))
            .toList());
  }

  Future<CategoryModel> createCategory({
    required String tenantId,
    required CategoryModel category,
  }) async {
    final id = const Uuid().v4();
    final newCat = CategoryModel(
      id: id,
      tenantId: tenantId,
      name: category.name,
      description: category.description,
      color: category.color,
      createdAt: DateTime.now(),
    );
    await _ref(tenantId).doc(id).set(newCat.toFirestore());
    return newCat;
  }

  Future<CategoryModel> updateCategory({
    required String tenantId,
    required CategoryModel category,
  }) async {
    await _ref(tenantId).doc(category.id).update(category.toFirestore());
    return category;
  }

  Future<void> deleteCategory({
    required String tenantId,
    required String categoryId,
  }) async {
    await _ref(tenantId).doc(categoryId).delete();
  }
}
