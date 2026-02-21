import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

/// Service for managing Firestore user collections.
///
/// This is an **optional** service. Enable it by passing
/// `createUserCollection: true` and a [FirebaseFirestore] instance
/// when creating FirebaseAuthRepository.
///
/// Supports multi-Firebase-app configurations through injected instances.
class FirestoreUserService {
  final FirebaseFirestore firestore;
  final String usersCollection;

  FirestoreUserService({
    required this.firestore,
    this.usersCollection = 'users',
  });

  /// Creates or updates a user document in Firestore.
  ///
  /// On first sign-in, creates a new document with basic profile data.
  /// On subsequent sign-ins, updates `lastLoginAt`.
  Future<void> createOrUpdateUserDocument(User user) async {
    try {
      final userDoc = firestore.collection(usersCollection).doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.set({
          // Only update lastLoginAt on subsequent logins.
          // We do NOT overwrite other fields to preserve user changes.
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Log but don't crash the auth flow.
      log('[FirestoreUserService] Error syncing user document', error: e);
    }
  }

  /// Updates specific fields in the user document.
  ///
  /// **Security Note**: This method explicitly blocks updates to immutable fields
  /// like `uid`, `createdAt`, and `email` (email should be updated via Auth).
  ///
  /// Throws [ArgumentError] if [data] contains restricted keys or is empty.
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    if (data.isEmpty) {
      throw ArgumentError('Update data cannot be empty');
    }

    const restrictedFields = <String>{'uid', 'createdAt', 'email'};
    final sensitiveUpdate = data.keys.any(
      (key) => restrictedFields.contains(key),
    );

    if (sensitiveUpdate) {
      throw ArgumentError(
        'Cannot update restricted fields: ${restrictedFields.join(', ')}',
      );
    }

    final userDoc = firestore.collection(usersCollection).doc(uid);
    await userDoc.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Returns a [DocumentReference] to the given user's document.
  DocumentReference<Map<String, dynamic>> getUserDocRef(String uid) {
    return firestore.collection(usersCollection).doc(uid);
  }

  /// Returns a [CollectionReference] to a subcollection under the user document.
  CollectionReference<Map<String, dynamic>> getUserSubcollection(
    String uid,
    String name,
  ) {
    return getUserDocRef(uid).collection(name);
  }

  /// Returns a stream of the user's document snapshot.
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return firestore.collection(usersCollection).doc(uid).snapshots();
  }

  /// Deletes the user's document.
  Future<void> deleteUserDocument(String uid) async {
    await firestore.collection(usersCollection).doc(uid).delete();
  }
}
