import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';

/// Base class for all authentication events.
sealed class AuthEvent {
  const AuthEvent();
}

/// Initialize the authentication session.
class InitializeAuthEvent extends AuthEvent {
  const InitializeAuthEvent();
}

/// Sign in with email and password.
class SignInWithEmailEvent extends AuthEvent {
  const SignInWithEmailEvent({required this.email, required this.password});
  final String email;
  final String password;
}

/// Register a new account with email and password.
class RegisterWithEmailEvent extends AuthEvent {
  const RegisterWithEmailEvent({required this.email, required this.password});
  final String email;
  final String password;
}

/// Sign in with Google.
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Sign in anonymously.
class SignInAnonymouslyEvent extends AuthEvent {
  const SignInAnonymouslyEvent();
}

/// Starts the phone number verification process.
class VerifyPhoneNumberEvent extends AuthEvent {
  const VerifyPhoneNumberEvent({required this.phoneNumber});
  final String phoneNumber;
}

/// Signs in with an SMS code.
class SignInWithSmsCodeEvent extends AuthEvent {
  const SignInWithSmsCodeEvent({
    required this.verificationId,
    required this.smsCode,
  });
  final String verificationId;
  final String smsCode;
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
  const RefreshCurrentUserEvent({this.isSilent = false});
  final bool isSilent;
}

/// Send password reset email.
class SendPasswordResetEvent extends AuthEvent {
  const SendPasswordResetEvent({required this.email});
  final String email;
}

/// Update the user's display name.
class UpdateDisplayNameEvent extends AuthEvent {
  const UpdateDisplayNameEvent({required this.name});
  final String name;
}

/// Update the user's password.
class UpdatePasswordEvent extends AuthEvent {
  const UpdatePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
  final String currentPassword;
  final String newPassword;
}

/// Internal event: authentication state changed (from stream).
class AuthStateChangedEvent extends AuthEvent {
  const AuthStateChangedEvent(this.user);
  final AuthUser? user;
}

class PhoneCodeSentInternalEvent extends AuthEvent {
  const PhoneCodeSentInternalEvent(this.verificationId, this.resendToken);
  final String verificationId;
  final int? resendToken;
}

class PhoneVerificationFailedInternalEvent extends AuthEvent {
  const PhoneVerificationFailedInternalEvent(this.failure);
  final AuthFailure failure;
}
