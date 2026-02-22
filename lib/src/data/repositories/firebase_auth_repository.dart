import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/data/models/auth_user_mapper.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/repositories/auth_repository.dart';
import 'package:remote_auth_module/src/services/auth_providers.dart';
import 'package:remote_auth_module/src/services/firestore_user_service.dart';
import 'package:remote_auth_module/src/services/phone_auth_service.dart';

/// Default Firebase implementation of [AuthRepository].
///
/// Supports:
/// - Multi-Firebase-app configurations (inject custom instances)
/// - Optional Firestore user collection management
/// - Email/Password and Google Sign-In
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final EmailAuthProvider _emailProvider;
  final GoogleAuthService _googleService;
  final PhoneAuthService _phoneService;
  final FirestoreUserService? _firestoreService;
  final bool _createUserCollection;

  /// Internal constructor — use the public factory instead.
  FirebaseAuthRepository._({
    required fb.FirebaseAuth auth,
    required bool createUserCollection,
    required EmailAuthProvider emailProvider,
    required GoogleAuthService googleService,
    required PhoneAuthService phoneService,
    FirestoreUserService? firestoreService,
  }) : _auth = auth,
       _createUserCollection = createUserCollection,
       _emailProvider = emailProvider,
       _googleService = googleService,
       _phoneService = phoneService,
       _firestoreService = firestoreService;

  /// Creates a [FirebaseAuthRepository].
  ///
  /// - [auth]: Optional custom FirebaseAuth instance (multi-app support).
  /// - [firestore]: Optional custom FirebaseFirestore instance.
  /// - [serverClientId]: The Web Client ID from Google Cloud Console.
  ///   **Required on Android** for Google Sign-In.
  /// - [clientId]: Optional OAuth client ID (used on iOS/web).
  /// - [createUserCollection]: Whether to create/update user documents in Firestore.
  /// - [usersCollectionName]: Name of the Firestore collection for user documents.
  factory FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String? serverClientId,
    String? clientId,
    bool createUserCollection = false,
    String usersCollectionName = 'users',
  }) {
    final effectiveAuth = auth ?? fb.FirebaseAuth.instance;
    return FirebaseAuthRepository._(
      auth: effectiveAuth,
      createUserCollection: createUserCollection,
      emailProvider: EmailAuthProvider(auth: effectiveAuth),
      googleService: GoogleAuthService(
        auth: effectiveAuth,
        serverClientId: serverClientId,
        clientId: clientId,
      ),
      phoneService: PhoneAuthService(auth: effectiveAuth),
      firestoreService:
          createUserCollection && firestore != null
              ? FirestoreUserService(
                firestore: firestore,
                usersCollection: usersCollectionName,
              )
              : null,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) => user?.toDomain());
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    return _auth.currentUser?.toDomain();
  }

  @override
  Future<AuthUser?> reloadCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    await currentUser.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser != null) {
      await _syncUserDocument(refreshedUser);
      return refreshedUser.toDomain();
    }
    return null;
  }

  @override
  Future<AuthUser?> initializeSession() async {
    try {
      // Bypass silent sign-in on Web. Firebase Auth handles session persistence
      // automatically on Web. Calling Google's silent sign-in simultaneously on
      // app start can cause NotAllowedError conflicts with the FedCM/Identity SDK.
      if (!kIsWeb) {
        await _googleService.signInSilently();
      }
    } catch (e) {
      log('[FirebaseAuthRepository] Silent sign-in failed: $e');
    }

    final user = _auth.currentUser;
    if (user != null) {
      await _syncUserDocument(user);
      return user.toDomain();
    }
    return null;
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authUser = await _emailProvider.signIn(
      email: email,
      password: password,
    );

    if (_auth.currentUser != null) {
      await _syncUserDocument(_auth.currentUser!);
    }
    return authUser;
  }

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authUser = await _emailProvider.register(
      email: email,
      password: password,
    );

    if (_auth.currentUser != null) {
      await _syncUserDocument(_auth.currentUser!);
    }
    return authUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final authUser = await _googleService.signIn();

    if (_auth.currentUser != null) {
      await _syncUserDocument(_auth.currentUser!);
    }
    return authUser;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'anonymous-sign-in-failed');
      }
      await _syncUserDocument(user);
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException exception) onVerificationFailed,
    required void Function(AuthUser user) onVerificationCompleted,
  }) async {
    return _phoneService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: (user) async {
        await _syncUserDocument(_auth.currentUser!);
        onVerificationCompleted(user);
      },
    );
  }

  @override
  Future<AuthUser> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final authUser = await _phoneService.signInWithSmsCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    if (_auth.currentUser != null) {
      await _syncUserDocument(_auth.currentUser!);
    }
    return authUser;
  }

  @override
  Future<void> signOut() async {
    // Sign out from Google first (non-critical if it fails).
    try {
      await _googleService.signOut();
    } catch (_) {}

    // Always sign out from Firebase Auth.
    await _emailProvider.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _emailProvider.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _emailProvider.sendPasswordReset(email: email);
  }

  @override
  Future<void> updateDisplayName({required String name}) async {
    await _emailProvider.updateDisplayName(name);
    if (_auth.currentUser != null) {
      await _syncUserDocument(_auth.currentUser!);
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _emailProvider.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // -- Private helpers --

  Future<void> _syncUserDocument(fb.User user) async {
    if (_createUserCollection && _firestoreService != null) {
      await _firestoreService.createOrUpdateUserDocument(user);
    }
  }
}
