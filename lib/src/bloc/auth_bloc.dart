// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_event.dart';
import 'package:remote_auth_module/src/bloc/auth_state.dart';
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/repositories/auth_repository.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

export 'package:remote_auth_module/src/bloc/auth_event.dart';
export 'package:remote_auth_module/src/bloc/auth_state.dart';

/// Internal event: authentication state changed (from stream).
class _AuthStateChangedEvent extends AuthEvent {
  const _AuthStateChangedEvent(this.user);
  final AuthUser? user;
}

class _PhoneCodeSentInternalEvent extends AuthEvent {
  const _PhoneCodeSentInternalEvent(this.verificationId, this.resendToken);
  final String verificationId;
  final int? resendToken;
}

class _PhoneVerificationFailedInternalEvent extends AuthEvent {
  const _PhoneVerificationFailedInternalEvent(this.exception);
  final AuthException exception;
}

/// BLoC for managing authentication state.
///
/// Requires an [AuthRepository] implementation (typically FirebaseAuthRepository).
/// The host app provides this through its DI system (GetIt, Injectable, etc.).
///
/// ```dart
/// // In your DI setup:
/// getIt.registerSingleton<AuthRepository>(
///   FirebaseAuthRepository(
///     auth: FirebaseAuth.instance,
///     firestore: FirebaseFirestore.instance,
///     createUserCollection: true,
///   ),
/// );
///
/// // Provide the BLoC:
/// BlocProvider(
///   create: (_) => AuthBloc(repository: getIt<AuthRepository>())
///     ..add(const InitializeAuthEvent()),
/// )
/// ```
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    RememberMeService? rememberMeService,
  }) : _repository = repository,
       _rememberMeService = rememberMeService ?? RememberMeService(),
       super(const AuthInitialState()) {
    // Register event handlers
    on<InitializeAuthEvent>(_onInitialize);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInAnonymouslyEvent>(_onSignInAnonymously);
    on<VerifyPhoneNumberEvent>(_onVerifyPhoneNumber);
    on<SignInWithSmsCodeEvent>(_onSignInWithSmsCode);
    on<SignOutEvent>(_onSignOut);
    on<SendEmailVerificationEvent>(_onSendEmailVerification);
    on<RefreshCurrentUserEvent>(_onRefreshCurrentUser);
    on<SendPasswordResetEvent>(_onSendPasswordReset);
    on<UpdateDisplayNameEvent>(_onUpdateDisplayName);
    on<UpdatePasswordEvent>(_onUpdatePassword);
    on<_AuthStateChangedEvent>(_onAuthStateChanged);
    on<_PhoneCodeSentInternalEvent>(_onPhoneCodeSent);
    on<_PhoneVerificationFailedInternalEvent>(_onPhoneVerificationFailed);

    _subscribeToAuthStateChanges();
  }
  final AuthRepository _repository;
  final RememberMeService _rememberMeService;
  StreamSubscription<AuthUser?>? _authStateSubscription;

  Future<void> _onInitialize(
    InitializeAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final shouldRememberSession = await _rememberMeService.load();
      if (!shouldRememberSession) {
        await _repository.signOut();
        emit(const UnauthenticatedState());
        return;
      }

      final user = await _repository.initializeSession();
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      log('[AuthBloc] Initialize failed', error: error, stackTrace: stackTrace);
      emit(const UnauthenticatedState());
    }
  }

  void _onAuthStateChanged(
    _AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) {
    // Skip re-emitting if we are already authenticated as the same user.
    // Firebase's authStateChanges stream always fires after a manual sign-in,
    // which would otherwise call onAuthenticated twice in the UI layer.
    final current = state;
    if (current is AuthenticatedState &&
        event.user?.id == current.user.id &&
        event.user?.isEmailVerified == current.user.isEmailVerified &&
        event.user?.displayName == current.user.displayName) {
      return;
    }
    _emitStateForUser(emit, event.user);
  }

  void _onPhoneCodeSent(
    _PhoneCodeSentInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(
      PhoneCodeSentState(
        verificationId: event.verificationId,
        resendToken: event.resendToken,
      ),
    );
  }

  void _onPhoneVerificationFailed(
    _PhoneVerificationFailedInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthErrorState(event.exception.message));
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'sign in with email');
    }
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      _emitStateForUser(emit, user);

      if (!user.isEmailVerified && !user.isOAuthUser) {
        add(const SendEmailVerificationEvent());
      }
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'register with email');
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signInWithGoogle();
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      if (error is GoogleSignInCancelledException) {
        emit(const UnauthenticatedState());
        return;
      }

      _emitFailure(emit, error, stackTrace, action: 'sign in with Google');
    }
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymouslyEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signInAnonymously();
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'sign in anonymously');
    }
  }

  Future<void> _onVerifyPhoneNumber(
    VerifyPhoneNumberEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _repository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          add(_PhoneCodeSentInternalEvent(verificationId, resendToken));
        },
        onVerificationFailed: (exception) {
          add(_PhoneVerificationFailedInternalEvent(exception));
        },
        onVerificationCompleted: (user) {
          add(_AuthStateChangedEvent(user));
        },
      );
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'verify phone number');
    }
  }

  Future<void> _onSignInWithSmsCode(
    SignInWithSmsCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signInWithSmsCode(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'sign in with SMS code');
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    try {
      await _repository.signOut();
      emit(const UnauthenticatedState());
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'sign out');
    }
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Note: We don't emit AuthLoadingState here by default to avoid
    // replacing a specialized page state (like EmailVerificationRequired),
    // but we can if the UI expects it. The pages use internal _isResendPending instead.
    try {
      log('[AuthBloc] Requesting email verification send...');
      await _repository.sendEmailVerification();
      log('[AuthBloc] Email verification sent successfully.');
      final user = await _repository.getCurrentUser();
      if (user != null) {
        emit(EmailVerificationSentState(user: user));
      } else {
        // Fallback for edge cases where user is suddenly null
        emit(
          const AuthErrorState('User not found after sending verification.'),
        );
        return;
      }

      // Give listeners a small amount of time to process the Sent state
      // before potentially navigating away/rebuilding via _emitStateForUser.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await _emitStateForCurrentUserSafely(emit, reload: true);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'send email verification');
      await _emitStateForCurrentUserSafely(emit, reload: true);
    }
  }

  Future<void> _onRefreshCurrentUser(
    RefreshCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.isSilent) {
      emit(const AuthLoadingState());
    }
    try {
      log('[AuthBloc] Refreshing current user (silent: ${event.isSilent})');
      await _emitStateForCurrentUser(emit, reload: true);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'refresh current user');
      await _emitStateForCurrentUserSafely(emit, reload: false);
    }
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      log('[AuthBloc] Requesting password reset email for: ${event.email}');
      await _repository.sendPasswordResetEmail(email: event.email);
      log('[AuthBloc] Password reset email sent successfully.');
      emit(const PasswordResetSentState());
      // We don't reload user here because they are usually unauthenticated.
      // Just emit current state to refresh UI.
      await _emitStateForCurrentUserSafely(emit, reload: false);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'send password reset');
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.updateDisplayName(name: event.name);
      emit(DisplayNameUpdatedState(event.name));
      await _emitStateForCurrentUser(emit, reload: true);
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'update display name');
    }
  }

  Future<void> _onUpdatePassword(
    UpdatePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.updatePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const PasswordUpdatedState());
      // Sign out after password change for security.
      add(const SignOutEvent());
    } catch (error, stackTrace) {
      _emitFailure(emit, error, stackTrace, action: 'update password');
    }
  }

  void _subscribeToAuthStateChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _repository.authStateChanges.listen((user) {
      add(_AuthStateChangedEvent(user));
    });
  }

  @override
  Future<void> close() async {
    await _authStateSubscription?.cancel();
    return super.close();
  }

  void _emitStateForUser(Emitter<AuthState> emit, AuthUser? user) {
    if (user == null) {
      emit(const UnauthenticatedState());
      return;
    }

    // OAuth users (Google, Apple, etc.) and Anonymous users don't need
    // email verification.
    if (!user.isEmailVerified && !user.isOAuthUser && !user.isAnonymous) {
      emit(EmailVerificationRequiredState(user));
      return;
    }

    emit(AuthenticatedState(user));
  }

  Future<void> _emitStateForCurrentUser(
    Emitter<AuthState> emit, {
    required bool reload,
  }) async {
    final user =
        reload
            ? await _repository.reloadCurrentUser()
            : await _repository.getCurrentUser();
    _emitStateForUser(emit, user);
  }

  Future<void> _emitStateForCurrentUserSafely(
    Emitter<AuthState> emit, {
    required bool reload,
  }) async {
    try {
      await _emitStateForCurrentUser(emit, reload: reload);
    } catch (error, stackTrace) {
      log(
        '[AuthBloc] Failed to evaluate current user state',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _emitFailure(
    Emitter<AuthState> emit,
    Object error,
    StackTrace stackTrace, {
    required String action,
  }) {
    log('[AuthBloc] Failed to $action', error: error, stackTrace: stackTrace);

    final message =
        error is AuthException
            ? error.message
            : 'Something went wrong. Please try again.';
    emit(AuthErrorState(message));
  }
}
