import 'package:flutter/foundation.dart';
import '../domain/entities/auth_user.dart';

/// Base class for all authentication states.
@immutable
abstract class AuthState {
  const AuthState();
}

/// Initial state before auth status is determined.
class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// Auth status is being checked (e.g., session initialization).
class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// User is authenticated.
class AuthenticatedState extends AuthState {
  final AuthUser user;
  const AuthenticatedState(this.user);
}

/// User is not authenticated.
class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

/// An error occurred during authentication.
class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
}

/// Password reset email was sent successfully.
class PasswordResetSentState extends AuthState {
  const PasswordResetSentState();
}

/// Email verification was sent.
class EmailVerificationSentState extends AuthState {
  const EmailVerificationSentState();
}

/// User registered but needs to verify email before proceeding.
class EmailVerificationRequiredState extends AuthState {
  final AuthUser user;
  const EmailVerificationRequiredState(this.user);
}

/// Display name was updated successfully.
class DisplayNameUpdatedState extends AuthState {
  final String newName;
  const DisplayNameUpdatedState(this.newName);
}

/// Password was updated successfully.
class PasswordUpdatedState extends AuthState {
  const PasswordUpdatedState();
}
