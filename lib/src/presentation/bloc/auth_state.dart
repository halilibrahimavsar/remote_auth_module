import 'package:equatable/equatable.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';

/// Base class for all authentication states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before auth status is determined.
final class AuthInitialState extends AuthState {
  const AuthInitialState();
}

/// Auth status is being checked (e.g., session initialization).
final class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

/// User is authenticated.
final class AuthenticatedState extends AuthState {
  const AuthenticatedState(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
final class UnauthenticatedState extends AuthState {
  const UnauthenticatedState();
}

/// An error occurred during authentication.
final class AuthErrorState extends AuthState {
  const AuthErrorState(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Password reset email was sent successfully.
final class PasswordResetSentState extends AuthState {
  const PasswordResetSentState();
}

/// Email verification was sent.
final class EmailVerificationSentState extends AuthState {
  const EmailVerificationSentState({required this.user});
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Phone code was successfully sent, waiting for user input.
final class PhoneCodeSentState extends AuthState {
  const PhoneCodeSentState({required this.verificationId, this.resendToken});
  final String verificationId;
  final int? resendToken;

  @override
  List<Object?> get props => [verificationId, resendToken];
}

/// User registered but needs to verify email before proceeding.
final class EmailVerificationRequiredState extends AuthState {
  const EmailVerificationRequiredState(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Display name was updated successfully.
final class DisplayNameUpdatedState extends AuthState {
  const DisplayNameUpdatedState(this.newName);
  final String newName;

  @override
  List<Object?> get props => [newName];
}

/// Password was updated successfully.
final class PasswordUpdatedState extends AuthState {
  const PasswordUpdatedState();
}
