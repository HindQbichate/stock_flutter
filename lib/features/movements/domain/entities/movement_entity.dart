import 'package:equatable/equatable.dart';

enum MovementType { inbound, outbound }

class MovementEntity extends Equatable {
  final String id;
  final String tenantId;
  final String productId;
  final String productName;
  final String productSku;
  final MovementType type;
  final int quantity;
  final String? note;
  final double? unitPrice;
  final DateTime createdAt;

  const MovementEntity({
    required this.id,
    required this.tenantId,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.type,
    required this.quantity,
    this.note,
    this.unitPrice,
    required this.createdAt,
  });

  bool get isInbound => type == MovementType.inbound;
  bool get isOutbound => type == MovementType.outbound;
  double get totalValue => (unitPrice ?? 0) * quantity;

  @override
  List<Object?> get props => [id, tenantId, productId, type, createdAt];
}
