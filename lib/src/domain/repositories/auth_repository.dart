import 'package:remote_auth_module/src/domain/entities/auth_user.dart';

/// Abstract interface for authentication operations.
///
/// Host apps can register their own implementation via GetIt/Injectable,
/// or use the provided FirebaseAuthRepository from the data layer.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the current user if authenticated, or `null`.
  Future<AuthUser?> getCurrentUser();

  /// Initializes the session (token refresh, silent sign-in, user doc sync).
  Future<AuthUser?> initializeSession();

  /// Signs in with email and password.
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in with Google.
  Future<AuthUser> signInWithGoogle();

  /// Signs out the current user.
  Future<void> signOut();

  /// Sends an email verification to the current user.
  Future<void> sendEmailVerification();

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Updates the current user's display name.
  Future<void> updateDisplayName({required String name});

  /// Updates the current user's password.
  ///
  /// Requires [currentPassword] for re-authentication.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Reloads current user data from remote auth source.
  Future<AuthUser?> reloadCurrentUser();
}
