import 'package:dartz/dartz.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';

/// Abstract interface for authentication operations.
///
/// Host apps can register their own implementation via GetIt/Injectable,
/// or use the provided FirebaseAuthRepository from the data layer.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the current user if authenticated, or `null`.
  Future<Either<AuthFailure, AuthUser?>> getCurrentUser();

  /// Initializes the session (token refresh, silent sign-in, user doc sync).
  Future<Either<AuthFailure, AuthUser?>> initializeSession();

  /// Signs in with email and password.
  Future<Either<AuthFailure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<Either<AuthFailure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in with Google.
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle();

  /// Signs in anonymously.
  Future<Either<AuthFailure, AuthUser>> signInAnonymously();

  /// Verifies a phone number for SMS authentication.
  ///
  /// Calls [onCodeSent] when the code is successfully sent.
  /// Calls [onVerificationFailed] if an error occurs.
  /// Calls [onVerificationCompleted] if auto-retrieval succeeds (Android).
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFailure failure) onVerificationFailed,
    required void Function(AuthUser user) onVerificationCompleted,
  });

  /// Signs in with the SMS code sent via [verifyPhoneNumber].
  Future<Either<AuthFailure, AuthUser>> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  });

  /// Signs out the current user.
  Future<Either<AuthFailure, Unit>> signOut();

  /// Sends an email verification to the current user.
  Future<Either<AuthFailure, Unit>> sendEmailVerification();

  /// Sends a password reset email.
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  });

  /// Updates the current user's display name.
  Future<Either<AuthFailure, Unit>> updateDisplayName({required String name});

  /// Updates the current user's password.
  ///
  /// Requires [currentPassword] for re-authentication.
  Future<Either<AuthFailure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Reloads current user data from remote auth source.
  Future<Either<AuthFailure, AuthUser?>> reloadCurrentUser();
}
