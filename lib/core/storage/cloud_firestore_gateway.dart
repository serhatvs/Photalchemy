import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';

/// Production [FirestoreGateway] backed by the real Cloud Firestore SDK
/// ([FirebaseFirestore]).
///
/// Maps Firebase [FirebaseException] error codes (`permission-denied`,
/// `unauthenticated`, `unavailable`) into [FirestoreSecurityException] so
/// domain repositories and UI handle live Cloud Firestore and rule-enforced
/// tests identically.
class CloudFirestoreGateway implements FirestoreGateway {
  CloudFirestoreGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> getDocument({
    required String path,
    required String? authenticatedUid,
  }) async {
    try {
      final snapshot = await _firestore.doc(path).get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } on FirebaseException catch (e) {
      throw FirestoreSecurityException(
        e.code,
        e.message ?? 'Cloud Firestore read failed (${e.code}).',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    required String? authenticatedUid,
  }) async {
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      return querySnapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreSecurityException(
        e.code,
        e.message ?? 'Cloud Firestore collection query failed (${e.code}).',
      );
    }
  }

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    required String? authenticatedUid,
  }) async {
    try {
      await _firestore.doc(path).set(data);
    } on FirebaseException catch (e) {
      throw FirestoreSecurityException(
        e.code,
        e.message ?? 'Cloud Firestore write failed (${e.code}).',
      );
    }
  }

  @override
  Future<void> deleteDocument({
    required String path,
    required String? authenticatedUid,
  }) async {
    try {
      await _firestore.doc(path).delete();
    } on FirebaseException catch (e) {
      throw FirestoreSecurityException(
        e.code,
        e.message ?? 'Cloud Firestore delete failed (${e.code}).',
      );
    }
  }
}
