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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthInitialState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Auth status is being checked (e.g., session initialization).
class AuthLoadingState extends AuthState {
  const AuthLoadingState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthLoadingState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// User is authenticated.
class AuthenticatedState extends AuthState {
  final AuthUser user;
  const AuthenticatedState(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthenticatedState && user == other.user;

  @override
  int get hashCode => Object.hash(runtimeType, user);
}

/// User is not authenticated.
class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnauthenticatedState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// An error occurred during authentication.
class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthErrorState && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

/// Password reset email was sent successfully.
class PasswordResetSentState extends AuthState {
  const PasswordResetSentState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PasswordResetSentState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Email verification was sent.
class EmailVerificationSentState extends AuthState {
  const EmailVerificationSentState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmailVerificationSentState;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// User registered but needs to verify email before proceeding.
class EmailVerificationRequiredState extends AuthState {
  final AuthUser user;
  const EmailVerificationRequiredState(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailVerificationRequiredState && user == other.user;

  @override
  int get hashCode => Object.hash(runtimeType, user);
}

/// Display name was updated successfully.
class DisplayNameUpdatedState extends AuthState {
  final String newName;
  const DisplayNameUpdatedState(this.newName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayNameUpdatedState && newName == other.newName;

  @override
  int get hashCode => Object.hash(runtimeType, newName);
}

/// Password was updated successfully.
class PasswordUpdatedState extends AuthState {
  const PasswordUpdatedState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PasswordUpdatedState;

  @override
  int get hashCode => runtimeType.hashCode;
}
