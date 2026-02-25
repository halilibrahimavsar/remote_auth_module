import 'package:equatable/equatable.dart';

/// Base class for authentication failures.
sealed class AuthFailure extends Equatable {
  const AuthFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure() : super('This account has been disabled.');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure() : super('Incorrect password.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('No account found with this email.');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
    : super('Too many requests. Please try again later.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
    : super('Password is too weak. Please use a stronger password.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
    : super('An account with this email already exists.');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('The email address is not valid.');
}

class UserNotLoggedInFailure extends AuthFailure {
  const UserNotLoggedInFailure() : super('No user is currently signed in.');
}

class InvalidCredentialFailure extends AuthFailure {
  const InvalidCredentialFailure()
    : super('The provided credential is invalid.');
}

class AccountExistsWithDifferentCredentialFailure extends AuthFailure {
  const AccountExistsWithDifferentCredentialFailure()
    : super('An account already exists with a different sign-in method.');
}

class OperationNotAllowedFailure extends AuthFailure {
  const OperationNotAllowedFailure()
    : super('This operation is not allowed. Contact support.');
}

class RequiresRecentLoginFailure extends AuthFailure {
  const RequiresRecentLoginFailure()
    : super('Please sign in again before performing this action.');
}

class PasswordChangeNotSupportedFailure extends AuthFailure {
  const PasswordChangeNotSupportedFailure()
    : super('Password can only be changed for email/password accounts.');
}

class PasswordResetFailure extends AuthFailure {
  const PasswordResetFailure(super.message);
}

class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure() : super('Google sign-in was cancelled.');
}

class GoogleSignInInterruptedFailure extends AuthFailure {
  const GoogleSignInInterruptedFailure()
    : super('Google sign-in was interrupted. Please try again.');
}

class GoogleSignInConfigurationFailure extends AuthFailure {
  const GoogleSignInConfigurationFailure()
    : super(
        'Google sign-in is not configured correctly. Check OAuth client IDs and app setup.',
      );
}

class GoogleSignInUnavailableFailure extends AuthFailure {
  const GoogleSignInUnavailableFailure()
    : super('Google sign-in is currently unavailable on this device.');
}

class GoogleSignInUserMismatchFailure extends AuthFailure {
  const GoogleSignInUserMismatchFailure()
    : super(
        'Google account changed unexpectedly. Please try signing in again.',
      );
}

class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure(super.message);
}

class SignOutFailure extends AuthFailure {
  const SignOutFailure(super.message);
}
