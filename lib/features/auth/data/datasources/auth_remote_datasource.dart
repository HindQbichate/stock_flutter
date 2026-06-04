import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_flutter/core/errors/failures.dart';
import 'package:stock_flutter/features/auth/data/models/user_model.dart';
import 'package:uuid/uuid.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    // Return minimal model — full model loaded async
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      tenantId: user.uid, // tenantId set after full load
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw const AuthException(message: 'Utilisateur introuvable');
      }

      return UserModel.fromFirestore(doc.data()!, uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseError(e.code));
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      // Each user gets their own tenantId (= their uid for SaaS isolation)
      final tenantId = const Uuid().v4();

      final userModel = UserModel(
        uid: uid,
        email: email,
        tenantId: tenantId,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      // Store user document
      await _firestore.collection('users').doc(uid).set(userModel.toFirestore());

      // Initialize tenant root document
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .set({'ownerId': uid, 'createdAt': Timestamp.now()});

      // Update Firebase Auth display name
      await credential.user!.updateDisplayName(displayName);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: _mapFirebaseError(e.code));
    }
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'Aucun compte avec cet email',
        'wrong-password' => 'Mot de passe incorrect',
        'email-already-in-use' => 'Cet email est déjà utilisé',
        'invalid-email' => 'Email invalide',
        'weak-password' => 'Mot de passe trop faible (min. 6 caractères)',
        'user-disabled' => 'Ce compte a été désactivé',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard',
        'network-request-failed' => 'Erreur réseau',
        _ => 'Erreur d\'authentification: $code',
      };
}
