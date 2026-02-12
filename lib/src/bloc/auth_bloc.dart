import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/exceptions/auth_exceptions.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Internal event: authentication state changed (from stream).
class _AuthStateChangedEvent extends AuthEvent {
  final AuthUser? user;
  const _AuthStateChangedEvent(this.user);
}

/// BLoC for managing authentication state.
///
/// Requires an [AuthRepository] implementation (typically [FirebaseAuthRepository]).
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
  final AuthRepository _repository;
  StreamSubscription? _authStateSubscription;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitialState()) {
    // Register event handlers
    on<InitializeAuthEvent>(_onInitialize);
    on<SignInWithEmailEvent>(_onSignInWithEmail);
    on<RegisterWithEmailEvent>(_onRegisterWithEmail);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignOutEvent>(_onSignOut);
    on<SendEmailVerificationEvent>(_onSendEmailVerification);
    on<SendPasswordResetEvent>(_onSendPasswordReset);
    on<UpdateDisplayNameEvent>(_onUpdateDisplayName);
    on<UpdatePasswordEvent>(_onUpdatePassword);
    on<_AuthStateChangedEvent>(_onAuthStateChanged);
  }

  Future<void> _onInitialize(
    InitializeAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.initializeSession();
      _emitStateForUser(emit, user);

      // Listen to auth state changes for reactive updates
      await _authStateSubscription?.cancel();
      _authStateSubscription = _repository.authStateChanges.listen((user) {
        add(_AuthStateChangedEvent(user));
      });
    } catch (error, stackTrace) {
      log(
        '[AuthBloc] Initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const UnauthenticatedState());
    }
  }

  void _onAuthStateChanged(
    _AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) {
    _emitStateForUser(emit, event.user);
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

      if (user == null) {
        emit(const AuthErrorState('Sign in failed.'));
        return;
      }

      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'sign in with email',
      );
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

      if (user != null) {
        emit(EmailVerificationRequiredState(user));
      } else {
        emit(const AuthErrorState('Registration failed.'));
      }
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'register with email',
      );
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        _emitStateForUser(emit, user);
      } else {
        // User cancelled the sign-in flow
        emit(const UnauthenticatedState());
      }
    } catch (error, stackTrace) {
      if (error is GoogleSignInCancelledException) {
        emit(const UnauthenticatedState());
        return;
      }

      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'sign in with Google',
      );
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _repository.signOut();
      emit(const UnauthenticatedState());
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'sign out',
      );
    }
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.sendEmailVerification();
      emit(const EmailVerificationSentState());

      final user = await _repository.getCurrentUser();
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'send email verification',
      );
    }
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _repository.sendPasswordResetEmail(email: event.email);
      emit(const PasswordResetSentState());
      final user = await _repository.getCurrentUser();
      _emitStateForUser(emit, user);
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'send password reset',
      );
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final success = await _repository.updateDisplayName(name: event.name);
      if (success) {
        emit(DisplayNameUpdatedState(event.name));
        final user = await _repository.getCurrentUser();
        _emitStateForUser(emit, user);
      } else {
        emit(const AuthErrorState('Failed to update display name.'));
      }
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'update display name',
      );
    }
  }

  Future<void> _onUpdatePassword(
    UpdatePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final success =
          await _repository.updatePassword(password: event.password);
      if (success) {
        emit(const PasswordUpdatedState());
        // Sign out after password change for security
        add(const SignOutEvent());
      } else {
        emit(const AuthErrorState('Failed to update password.'));
      }
    } catch (error, stackTrace) {
      _emitFailure(
        emit,
        error,
        stackTrace,
        action: 'update password',
      );
    }
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

    if (!user.isEmailVerified) {
      emit(EmailVerificationRequiredState(user));
      return;
    }

    emit(AuthenticatedState(user));
  }

  void _emitFailure(
    Emitter<AuthState> emit,
    Object error,
    StackTrace stackTrace, {
    required String action,
  }) {
    log(
      '[AuthBloc] Failed to $action',
      error: error,
      stackTrace: stackTrace,
    );

    final message = error is AuthException
        ? error.message
        : 'Something went wrong. Please try again.';
    emit(AuthErrorState(message));
  }
}
