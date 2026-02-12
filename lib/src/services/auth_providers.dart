import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/exceptions/auth_exceptions.dart';
import '../domain/entities/auth_user.dart';
import '../data/models/auth_user_mapper.dart';

/// Handles email/password and common Firebase Auth operations.
class EmailAuthProvider {
  final FirebaseAuth auth;

  EmailAuthProvider({required this.auth});

  Future<AuthUser?> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user?.toDomain();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user?.toDomain();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInException();
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      throw PasswordResetException(e.message ?? e.code);
    }
  }

  Future<bool> updateDisplayName(String name) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInException();

    try {
      await user.updateDisplayName(name);
      await user.reload();
      return true;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }

  Future<bool> updatePassword(String password) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInException();

    try {
      await user.updatePassword(password);
      return true;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw SignOutException('Failed to sign out: $e');
    }
  }
}

/// Handles Google Sign-In operations.
///
/// Uses the `google_sign_in` v7 singleton API.
/// The [FirebaseAuth] instance is injectable for multi-app support.
///
/// On Android, [serverClientId] (the Web Client ID from Google Cloud Console)
/// is **required** by the underlying SDK.
///
/// ```dart
/// GoogleAuthService(
///   auth: FirebaseAuth.instance,
///   serverClientId: '123456789-abc.apps.googleusercontent.com',
/// )
/// ```
class GoogleAuthService {
  final FirebaseAuth auth;
  final GoogleSignIn _googleSignIn;
  final String? serverClientId;
  final String? clientId;

  static Future<void>? _initializeFuture;
  static ({String? serverClientId, String? clientId})? _initConfig;
  static const List<String> _firebaseScopes = <String>['email'];

  GoogleAuthService({
    required this.auth,
    this.serverClientId,
    this.clientId,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Ensures GoogleSignIn is initialized exactly once.
  ///
  /// google_sign_in 7.x requires initialize() before any other call.
  Future<void> _ensureInitialized() async {
    final requestedConfig = (
      serverClientId: serverClientId,
      clientId: clientId,
    );
    final existingConfig = _initConfig;
    if (existingConfig != null && existingConfig != requestedConfig) {
      log(
        '[GoogleAuthService] initialize called with different config. '
        'Existing: $existingConfig, Requested: $requestedConfig',
      );
    }

    _initConfig ??= requestedConfig;
    _initializeFuture ??= _googleSignIn.initialize(
      serverClientId: serverClientId,
      clientId: clientId,
    );
    try {
      await _initializeFuture;
    } catch (_) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<AuthUser?> signIn() async {
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const GoogleSignInUnavailableException();
      }

      await _ensureInitialized();

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: _firebaseScopes,
      );
      final googleAuth = googleUser.authentication;
      String? accessToken;
      final initialAuthorization = await googleUser.authorizationClient
          .authorizationForScopes(_firebaseScopes);
      accessToken = initialAuthorization?.accessToken;

      final idToken = googleAuth.idToken;
      final hasIdToken = idToken != null && idToken.isNotEmpty;
      final hasAccessToken = accessToken != null && accessToken.isNotEmpty;

      if (!hasIdToken && !hasAccessToken) {
        final promptedAuthorization = await googleUser.authorizationClient
            .authorizeScopes(_firebaseScopes);
        accessToken = promptedAuthorization.accessToken;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      return userCredential.user?.toDomain();
    } on GoogleSignInException catch (e, stackTrace) {
      log(
        '[GoogleAuthService] GoogleSignInException: ${e.code} ${e.description}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _mapGoogleSignInError(e);
    } on UnsupportedError catch (e, stackTrace) {
      log(
        '[GoogleAuthService] Unsupported sign-in flow on this platform',
        error: e,
        stackTrace: stackTrace,
      );
      throw const GoogleSignInUnavailableException();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }

  /// Attempts a lightweight (silent) authentication.
  ///
  /// This is non-critical — failures are silently swallowed.
  /// On Android, this requires [serverClientId] to be set.
  Future<void> signInSilently() async {
    try {
      await _ensureInitialized();

      // attemptLightweightAuthentication returns Future? (nullable).
      // We must await the returned future to catch async errors.
      final future = _googleSignIn.attemptLightweightAuthentication();
      if (future != null) {
        await future;
      }
    } catch (_) {
      // Non-critical: don't crash on silent refresh failure.
      // Common reasons: no previous sign-in, network issues, etc.
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Non-critical
    }
  }

  AuthException _mapGoogleSignInError(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled =>
        const GoogleSignInCancelledException(),
      GoogleSignInExceptionCode.interrupted =>
        const GoogleSignInInterruptedException(),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        const GoogleSignInConfigurationException(),
      GoogleSignInExceptionCode.uiUnavailable =>
        const GoogleSignInUnavailableException(),
      GoogleSignInExceptionCode.userMismatch =>
        const GoogleSignInUserMismatchException(),
      _ => GenericAuthException(cause: error),
    };
  }
}
