import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/core/logging/app_logger.dart';
import 'package:remote_auth_module/src/data/models/auth_user_dto.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';

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
        throw const UnexpectedAuthFailure('user-not-created');
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
        throw const UnexpectedAuthFailure('missing-authenticated-user');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    if (user == null) {
      AppLogger.w(
        '[EmailAuthProvider] Cannot send verification: No user logged in.',
      );
      throw const UserNotLoggedInFailure();
    }
    try {
      AppLogger.d(
        '[EmailAuthProvider] Triggering user.sendEmailVerification()...',
      );
      await user.sendEmailVerification();
      AppLogger.d(
        '[EmailAuthProvider] user.sendEmailVerification() call finished.',
      );
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.e(
        '[EmailAuthProvider] FirebaseAuthException during verification: ${e.code}',
        error: e,
      );
      throw mapFirebaseAuthCode(e.code);
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      AppLogger.d(
        '[EmailAuthProvider] Triggering auth.sendPasswordResetEmail...',
      );
      await auth.sendPasswordResetEmail(email: email);
      AppLogger.d(
        '[EmailAuthProvider] auth.sendPasswordResetEmail() call finished.',
      );
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.e(
        '[EmailAuthProvider] FirebaseAuthException during password reset: ${e.code}',
        error: e,
      );
      throw PasswordResetFailure(e.message ?? e.code);
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInFailure();

    try {
      await user.updateDisplayName(name);
      await user.reload();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw UnexpectedAuthFailure(e.toString());
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw const UserNotLoggedInFailure();
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const PasswordChangeNotSupportedFailure();
    }

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw UnexpectedAuthFailure(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw SignOutFailure('Failed to sign out: $e');
    }
  }
}

/// Handles Google Sign-In operations.
class GoogleAuthService {
  final fb.FirebaseAuth auth;
  final GoogleSignIn _googleSignIn;
  final String? serverClientId;
  final String? clientId;

  Future<void>? _initializeFuture;
  ({String? serverClientId, String? clientId})? _initConfig;
  static const List<String> _firebaseScopes = <String>['email'];

  static bool _isOperationInProgress = false;

  GoogleAuthService({
    required this.auth,
    this.serverClientId,
    this.clientId,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    final requestedConfig = (
      serverClientId: serverClientId,
      clientId: clientId,
    );
    final existingConfig = _initConfig;
    if (existingConfig != null && existingConfig != requestedConfig) {
      AppLogger.w(
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
      AppLogger.w(
        '[GoogleAuthService] Sign-in already in progress. Ignoring concurrent request.',
      );
      throw const GoogleSignInInterruptedFailure();
    }

    _isOperationInProgress = true;
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        AppLogger.i(
          '[GoogleAuthService] Platform does not support native authenticate. Falling back to Firebase Popup.',
        );
        return await _signInWithFirebasePopup();
      }

      await _ensureInitialized();

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: _firebaseScopes,
      );
      final googleAuth = await googleUser.authentication;
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
        throw const UnexpectedAuthFailure('missing-google-auth-user');
      }
      return user.toDomain();
    } on GoogleSignInException catch (e, stackTrace) {
      AppLogger.e(
        '[GoogleAuthService] GoogleSignInException: ${e.code} ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      throw _mapGoogleSignInError(e);
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[GoogleAuthService] Generic error during signIn(): $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw UnexpectedAuthFailure(e.toString());
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<AuthUser> _signInWithFirebasePopup() async {
    try {
      final provider = fb.GoogleAuthProvider();
      for (final scope in _firebaseScopes) {
        provider.addScope(scope);
      }

      final userCredential = await auth.signInWithPopup(provider);
      AppLogger.i(
        '[GoogleAuthService] Popup sign-in successful: ${userCredential.user?.uid}',
      );
      final user = userCredential.user;
      if (user == null) {
        throw const UnexpectedAuthFailure('missing-google-popup-user');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.w(
        '[GoogleAuthService] FirebaseAuthException during popup: ${e.code} - ${e.message}',
        error: e,
      );
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        throw const GoogleSignInCancelledFailure();
      }
      throw mapFirebaseAuthCode(e.code);
    } catch (e, stackTrace) {
      AppLogger.e(
        '[GoogleAuthService] Generic error during _signInWithFirebasePopup(): $e',
        error: e,
        stackTrace: stackTrace,
      );
      throw UnexpectedAuthFailure(e.toString());
    }
  }

  Future<void> signInSilently() async {
    if (_isOperationInProgress) {
      AppLogger.d(
        '[GoogleAuthService] Operation already in progress. Skipping silent sign-in.',
      );
      return;
    }

    _isOperationInProgress = true;
    try {
      await _ensureInitialized();

      final future = _googleSignIn.attemptLightweightAuthentication();
      if (future != null) {
        await future.timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      AppLogger.d('[GoogleAuthService] Silent sign-in failed or timed out: $e');
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

  AuthFailure _mapGoogleSignInError(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled =>
        const GoogleSignInCancelledFailure(),
      GoogleSignInExceptionCode.interrupted =>
        const GoogleSignInInterruptedFailure(),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        const GoogleSignInConfigurationFailure(),
      GoogleSignInExceptionCode.uiUnavailable =>
        const GoogleSignInUnavailableFailure(),
      GoogleSignInExceptionCode.userMismatch =>
        const GoogleSignInUserMismatchFailure(),
      _ => UnexpectedAuthFailure(error.code.name),
    };
  }
}
