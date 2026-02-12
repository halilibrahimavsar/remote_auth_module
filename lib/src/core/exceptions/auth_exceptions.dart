/// Base class for all authentication exceptions.
sealed class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class UserDisabledException extends AuthException {
  const UserDisabledException() : super('This account has been disabled.');
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException() : super('Incorrect password.');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('No account found with this email.');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
      : super('Too many requests. Please try again later.');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Password is too weak. Please use a stronger password.');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('An account with this email already exists.');
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException() : super('The email address is not valid.');
}

class UserNotLoggedInException extends AuthException {
  const UserNotLoggedInException() : super('No user is currently signed in.');
}

class InvalidCredentialException extends AuthException {
  const InvalidCredentialException()
      : super('The provided credential is invalid.');
}

class AccountExistsWithDifferentCredentialException extends AuthException {
  const AccountExistsWithDifferentCredentialException()
      : super('An account already exists with a different sign-in method.');
}

class OperationNotAllowedException extends AuthException {
  const OperationNotAllowedException()
      : super('This operation is not allowed. Contact support.');
}

class RequiresRecentLoginException extends AuthException {
  const RequiresRecentLoginException()
      : super('Please sign in again before performing this action.');
}

class PasswordResetException extends AuthException {
  const PasswordResetException(super.message);
}

class GenericAuthException extends AuthException {
  final Object? cause;
  const GenericAuthException({this.cause})
      : super('An unexpected error occurred.');

  @override
  String toString() => cause?.toString() ?? message;
}

class SignOutException extends AuthException {
  const SignOutException(super.message);
}

class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException()
      : super('Google sign-in was cancelled.');
}

class GoogleSignInInterruptedException extends AuthException {
  const GoogleSignInInterruptedException()
      : super('Google sign-in was interrupted. Please try again.');
}

class GoogleSignInConfigurationException extends AuthException {
  const GoogleSignInConfigurationException()
      : super(
          'Google sign-in is not configured correctly. Check OAuth client IDs and app setup.',
        );
}

class GoogleSignInUnavailableException extends AuthException {
  const GoogleSignInUnavailableException()
      : super('Google sign-in is currently unavailable on this device.');
}

class GoogleSignInUserMismatchException extends AuthException {
  const GoogleSignInUserMismatchException()
      : super(
            'Google account changed unexpectedly. Please try signing in again.');
}


