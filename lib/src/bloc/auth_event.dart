import 'package:flutter/foundation.dart';

/// Base class for all authentication events.
@immutable
abstract class AuthEvent {
  const AuthEvent();
}

/// Initialize the authentication session.
class InitializeAuthEvent extends AuthEvent {
  const InitializeAuthEvent();
}

/// Sign in with email and password.
class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  const SignInWithEmailEvent({required this.email, required this.password});
}

/// Register a new account with email and password.
class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  const RegisterWithEmailEvent({required this.email, required this.password});
}

/// Sign in with Google.
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Sign out the current user.
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

/// Send email verification.
class SendEmailVerificationEvent extends AuthEvent {
  const SendEmailVerificationEvent();
}

/// Refreshes current user state from remote auth provider.
class RefreshCurrentUserEvent extends AuthEvent {
  const RefreshCurrentUserEvent();
}

/// Send password reset email.
class SendPasswordResetEvent extends AuthEvent {
  final String email;
  const SendPasswordResetEvent({required this.email});
}

/// Update the user's display name.
class UpdateDisplayNameEvent extends AuthEvent {
  final String name;
  const UpdateDisplayNameEvent({required this.name});
}

/// Update the user's password.
class UpdatePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  const UpdatePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
}
