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

class PasswordChangeNotSupportedException extends AuthException {
  const PasswordChangeNotSupportedException()
    : super('Password can only be changed for email/password accounts.');
}

class PasswordResetException extends AuthException {
  const PasswordResetException(super.message);
}

class GenericAuthException extends AuthException {
  final Object? cause;
  const GenericAuthException({this.cause})
    : super('An unexpected error occurred.');

  // Removed toString override to prevent leaking internal error details to UI.
  // Use 'cause' only for internal logging.
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
        'Google account changed unexpectedly. Please try signing in again.',
      );
}

/// Maps Firebase Auth error codes to typed [AuthException]s.
///
/// Shared by EmailAuthProvider and GoogleAuthService to avoid duplication.
AuthException mapFirebaseAuthCode(String code) {
  return switch (code) {
    'weak-password' => const WeakPasswordException(),
    'email-already-in-use' => const EmailAlreadyInUseException(),
    'invalid-email' => const InvalidEmailException(),
    'too-many-requests' => const TooManyRequestsException(),
    'user-disabled' => const UserDisabledException(),
    'user-not-found' => const UserNotFoundException(),
    'wrong-password' => const WrongPasswordException(),
    'invalid-credential' => const InvalidCredentialException(),
    'requires-recent-login' => const RequiresRecentLoginException(),
    'operation-not-allowed' => const OperationNotAllowedException(),
    'account-exists-with-different-credential' =>
      const AccountExistsWithDifferentCredentialException(),
    _ => GenericAuthException(cause: code),
  };
}
