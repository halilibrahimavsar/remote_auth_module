import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';

/// Maps Firebase Auth error codes to typed [AuthFailure]s.
///
/// Shared by EmailAuthProvider and GoogleAuthService to avoid duplication.
AuthFailure mapFirebaseAuthCode(String code) {
  return switch (code) {
    'weak-password' => const WeakPasswordFailure(),
    'email-already-in-use' => const EmailAlreadyInUseFailure(),
    'invalid-email' => const InvalidEmailFailure(),
    'too-many-requests' => const TooManyRequestsFailure(),
    'user-disabled' => const UserDisabledFailure(),
    'user-not-found' => const UserNotFoundFailure(),
    'wrong-password' => const WrongPasswordFailure(),
    'invalid-credential' => const InvalidCredentialFailure(),
    'requires-recent-login' => const RequiresRecentLoginFailure(),
    'operation-not-allowed' => const OperationNotAllowedFailure(),
    'account-exists-with-different-credential' =>
      const AccountExistsWithDifferentCredentialFailure(),
    _ => UnexpectedAuthFailure(code),
  };
}
