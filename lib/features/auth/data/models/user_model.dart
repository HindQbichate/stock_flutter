import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_flutter/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.tenantId,
    super.displayName,
    super.photoUrl,
    required super.createdAt,
  });

  factory UserModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return UserModel(
      uid: uid,
      email: data['email'] as String,
      tenantId: data['tenantId'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'tenantId': tenantId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      tenantId: entity.tenantId,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
    );
  }
}
