import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/data/models/auth_user_mapper.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';

/// Handles email/password and common Firebase Auth operations.
class EmailAuthProvider {
  final fb.FirebaseAuth auth;

  EmailAuthProvider({required this.auth});

  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'user-not-created');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'missing-authenticated-user');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) {
      log('[EmailAuthProvider] Cannot send verification: No user logged in.');
      throw const UserNotLoggedInException();
    }
    try {
      log('[EmailAuthProvider] Triggering user.sendEmailVerification()...');
      await user.sendEmailVerification();
      log('[EmailAuthProvider] user.sendEmailVerification() call finished.');
    } on fb.FirebaseAuthException catch (e) {
      log(
        '[EmailAuthProvider] FirebaseAuthException during verification: ${e.code}',
        error: e,
      );
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      log('[EmailAuthProvider] Triggering auth.sendPasswordResetEmail...');
      await auth.sendPasswordResetEmail(email: email);
      log('[EmailAuthProvider] auth.sendPasswordResetEmail() call finished.');
    } on fb.FirebaseAuthException catch (e) {
      log(
        '[EmailAuthProvider] FirebaseAuthException during password reset: ${e.code}',
        error: e,
      );
      throw PasswordResetException(e.message ?? e.code);
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInException();

    try {
      await user.updateDisplayName(name);
      await user.reload();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInException();
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const PasswordChangeNotSupportedException();
    }

    try {
      // Re-authenticate user to ensure they are who they say they are
      // This is critical for sensitive operations like changing password
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
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
/// The FirebaseAuth instance is injectable for multi-app support.
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
  final fb.FirebaseAuth auth;
  final GoogleSignIn _googleSignIn;
  final String? serverClientId;
  final String? clientId;

  Future<void>? _initializeFuture;
  ({String? serverClientId, String? clientId})? _initConfig;
  static const List<String> _firebaseScopes = <String>['email'];

  /// Prevent concurrent sign-in attempts which cause NotAllowedError on Web.
  static bool _isOperationInProgress = false;

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

  Future<AuthUser> signIn() async {
    if (_isOperationInProgress) {
      log(
        '[GoogleAuthService] Sign-in already in progress. Ignoring concurrent request.',
      );
      throw const GoogleSignInInterruptedException();
    }

    _isOperationInProgress = true;
    try {
      // Web/Desktop: native google_sign_in is unsupported, use Firebase
      // Auth's built-in GoogleAuthProvider with signInWithPopup instead.
      if (!_googleSignIn.supportsAuthenticate()) {
        return await _signInWithFirebasePopup();
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

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'missing-google-auth-user');
      }
      return user.toDomain();
    } on GoogleSignInException catch (e, stackTrace) {
      log(
        '[GoogleAuthService] GoogleSignInException: ${e.code} ${e.description}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _mapGoogleSignInError(e);
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    } finally {
      _isOperationInProgress = false;
    }
  }

  /// Web/Desktop fallback: uses Firebase Auth's GoogleAuthProvider directly.
  ///
  /// On Web this triggers signInWithPopup; on Desktop it triggers
  /// signInWithProvider. No google_sign_in plugin dependency needed.
  Future<AuthUser> _signInWithFirebasePopup() async {
    try {
      final provider = fb.GoogleAuthProvider();
      for (final scope in _firebaseScopes) {
        provider.addScope(scope);
      }

      final userCredential = await auth.signInWithProvider(provider);
      final user = userCredential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'missing-google-popup-user');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        throw const GoogleSignInCancelledException();
      }
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
    if (_isOperationInProgress) {
      log(
        '[GoogleAuthService] Operation already in progress. Skipping silent sign-in.',
      );
      return;
    }

    _isOperationInProgress = true;
    try {
      await _ensureInitialized();

      // attemptLightweightAuthentication returns Future? (nullable).
      // We must await the returned future to catch async errors.
      final future = _googleSignIn.attemptLightweightAuthentication();
      if (future != null) {
        // Add a safety timeout to prevent indefinite hangs on Android
        await future.timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      log('[GoogleAuthService] Silent sign-in failed or timed out: $e');
      // Non-critical: don't crash on silent refresh failure.
      // Common reasons: no previous sign-in, network issues, timeout.
    } finally {
      _isOperationInProgress = false;
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
