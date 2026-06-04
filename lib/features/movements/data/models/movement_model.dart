import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_flutter/core/constants/app_constants.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stock_flutter/features/movements/domain/entities/movement_entity.dart';
import 'package:stock_flutter/features/products/data/datasources/product_remote_datasource.dart';
import 'package:stock_flutter/features/products/presentation/providers/product_provider.dart';
import 'package:uuid/uuid.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class MovementModel extends MovementEntity {
  const MovementModel({
    required super.id,
    required super.tenantId,
    required super.productId,
    required super.productName,
    required super.productSku,
    required super.type,
    required super.quantity,
    super.note,
    super.unitPrice,
    required super.createdAt,
  });

  factory MovementModel.fromFirestore(DocumentSnapshot doc, String tenantId) {
    final data = doc.data() as Map<String, dynamic>;
    return MovementModel(
      id: doc.id,
      tenantId: tenantId,
      productId: data['productId'] as String,
      productName: data['productName'] as String? ?? '',
      productSku: data['productSku'] as String? ?? '',
      type: data['type'] == AppConstants.movementIn
          ? MovementType.inbound
          : MovementType.outbound,
      quantity: (data['quantity'] as num).toInt(),
      note: data['note'] as String?,
      unitPrice: data['unitPrice'] != null
          ? (data['unitPrice'] as num).toDouble()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productId': productId,
        'productName': productName,
        'productSku': productSku,
        'type': type == MovementType.inbound
            ? AppConstants.movementIn
            : AppConstants.movementOut,
        'quantity': quantity,
        'note': note,
        'unitPrice': unitPrice,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── DataSource ────────────────────────────────────────────────────────────
class MovementRemoteDataSource {
  final FirebaseFirestore _firestore;

  MovementRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _movementsRef(String tenantId) {
    return _firestore
        .collection(AppConstants.tenantsCollection)
        .doc(tenantId)
        .collection(AppConstants.movementsCollection);
  }

  CollectionReference<Map<String, dynamic>> _productsRef(String tenantId) {
    return _firestore
        .collection(AppConstants.tenantsCollection)
        .doc(tenantId)
        .collection(AppConstants.productsCollection);
  }

  Stream<List<MovementModel>> watchMovements(String tenantId) {
    return _movementsRef(tenantId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MovementModel.fromFirestore(doc, tenantId))
            .toList());
  }

  Stream<List<MovementModel>> watchMovementsByDateRange({
    required String tenantId,
    required DateTime from,
    required DateTime to,
  }) {
    return _movementsRef(tenantId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from),
            isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MovementModel.fromFirestore(doc, tenantId))
            .toList());
  }

  /// Creates movement and atomically updates product quantity
  Future<MovementModel> createMovement({
    required String tenantId,
    required MovementModel movement,
  }) async {
    final id = const Uuid().v4();
    final newMovement = MovementModel(
      id: id,
      tenantId: tenantId,
      productId: movement.productId,
      productName: movement.productName,
      productSku: movement.productSku,
      type: movement.type,
      quantity: movement.quantity,
      note: movement.note,
      unitPrice: movement.unitPrice,
      createdAt: DateTime.now(),
    );

    // Use Firestore transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      final productRef =
          _productsRef(tenantId).doc(movement.productId);
      final productDoc = await transaction.get(productRef);

      if (!productDoc.exists) {
        throw const NotFoundException();
      }

      final currentQty = (productDoc.data()!['quantity'] as num).toInt();
      int newQty;

      if (movement.type == MovementType.inbound) {
        newQty = currentQty + movement.quantity;
      } else {
        newQty = currentQty - movement.quantity;
        if (newQty < 0) {
          throw InsufficientStockException(
            message:
                'Stock insuffisant. Disponible: $currentQty, Demandé: ${movement.quantity}',
          );
        }
      }

      // Update product quantity
      transaction.update(productRef, {'quantity': newQty, 'updatedAt': Timestamp.now()});

      // Create movement record
      transaction.set(
        _movementsRef(tenantId).doc(id),
        newMovement.toFirestore(),
      );
    });

    return newMovement;
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────
final movementDataSourceProvider = Provider<MovementRemoteDataSource>((ref) {
  return MovementRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

final movementsStreamProvider = StreamProvider<List<MovementEntity>>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId == null) return const Stream.empty();

  return ref.watch(movementDataSourceProvider).watchMovements(tenantId);
});

// ─── Movement Notifier ─────────────────────────────────────────────────────
class MovementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  MovementNotifier(this._ref) : super(const AsyncValue.data(null));

  String? get _tenantId => _ref.read(currentTenantIdProvider);

  Future<bool> createEntry({
    required String productId,
    required String productName,
    required String productSku,
    required int quantity,
    String? note,
    double? unitPrice,
  }) =>
      _createMovement(
        productId: productId,
        productName: productName,
        productSku: productSku,
        type: MovementType.inbound,
        quantity: quantity,
        note: note,
        unitPrice: unitPrice,
      );

  Future<bool> createSale({
    required String productId,
    required String productName,
    required String productSku,
    required int quantity,
    String? note,
    double? unitPrice,
  }) =>
      _createMovement(
        productId: productId,
        productName: productName,
        productSku: productSku,
        type: MovementType.outbound,
        quantity: quantity,
        note: note,
        unitPrice: unitPrice,
      );

  Future<bool> _createMovement({
    required String productId,
    required String productName,
    required String productSku,
    required MovementType type,
    required int quantity,
    String? note,
    double? unitPrice,
  }) async {
    final tenantId = _tenantId;
    if (tenantId == null) return false;

    state = const AsyncValue.loading();

    try {
      final movement = MovementModel(
        id: '',
        tenantId: tenantId,
        productId: productId,
        productName: productName,
        productSku: productSku,
        type: type,
        quantity: quantity,
        note: note,
        unitPrice: unitPrice,
        createdAt: DateTime.now(),
      );

      await _ref
          .read(movementDataSourceProvider)
          .createMovement(tenantId: tenantId, movement: movement);

      state = const AsyncValue.data(null);
      return true;
    } on InsufficientStockException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }
}

final movementNotifierProvider =
    StateNotifierProvider<MovementNotifier, AsyncValue<void>>(
  (ref) => MovementNotifier(ref),
);
