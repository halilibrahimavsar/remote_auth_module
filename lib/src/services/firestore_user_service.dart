import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

/// Service for managing Firestore user collections.
///
/// This is an **optional** service. Enable it by passing
/// `createUserCollection: true` and a [FirebaseFirestore] instance
/// when creating the [FirebaseAuthRepository].
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
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Log but don't crash the auth flow.
      log('[FirestoreUserService] Error syncing user document', error: e);
    }
  }

  /// Updates specific fields in the user document.
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    final userDoc = firestore.collection(usersCollection).doc(uid);
    await userDoc.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Returns a [DocumentReference] to the given user's document.
  DocumentReference getUserDocRef(String uid) {
    return firestore.collection(usersCollection).doc(uid);
  }

  /// Returns a [CollectionReference] to a subcollection under the user document.
  CollectionReference getUserSubcollection(String uid, String name) {
    return getUserDocRef(uid).collection(name);
  }

  /// Returns a stream of the user's document snapshot.
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return firestore.collection(usersCollection).doc(uid).snapshots();
  }

  /// Deletes the user's document.
  Future<void> deleteUserDocument(String uid) async {
    await firestore.collection(usersCollection).doc(uid).delete();
  }
}
