import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/logging/app_logger.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';
import 'package:remote_auth_module/src/domain/repositories/auth_repository.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_event.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_state.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

export 'package:remote_auth_module/src/presentation/bloc/auth_event.dart';
export 'package:remote_auth_module/src/presentation/bloc/auth_state.dart';

/// BLoC for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    RememberMeService? rememberMeService,
  }) : _repository = repository,
       _rememberMeService = rememberMeService ?? RememberMeService(),
       super(const AuthInitialState()) {
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
    on<AuthStateChangedEvent>(_onAuthStateChanged);
    on<PhoneCodeSentInternalEvent>(_onPhoneCodeSent);
    on<PhoneVerificationFailedInternalEvent>(_onPhoneVerificationFailed);

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

      final result = await _repository.initializeSession();
      result.fold((failure) {
        AppLogger.w('[AuthBloc] Initialize session failed: ${failure.message}');
        emit(const UnauthenticatedState());
      }, (user) => _emitStateForUser(emit, user));
    } catch (error, stackTrace) {
      AppLogger.e(
        '[AuthBloc] Initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const UnauthenticatedState());
    }
  }

  void _onAuthStateChanged(
    AuthStateChangedEvent event,
    Emitter<AuthState> emit,
  ) {
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
    PhoneCodeSentInternalEvent event,
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
    PhoneVerificationFailedInternalEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthErrorState(event.failure.message));
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.signInWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );
    result.fold((failure) {
      AppLogger.d('[AuthBloc] SignInWithEmail failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
    }, (user) => _emitStateForUser(emit, user));
  }

  Future<void> _onRegisterWithEmail(
    RegisterWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.signUpWithEmailAndPassword(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        AppLogger.d('[AuthBloc] RegisterWithEmail failed: ${failure.message}');
        emit(AuthErrorState(failure.message));
      },
      (user) {
        _emitStateForUser(emit, user);

        if (!user.isEmailVerified && !user.isOAuthUser) {
          add(const SendEmailVerificationEvent());
        }
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.signInWithGoogle();
    result.fold((failure) {
      if (failure is GoogleSignInCancelledFailure) {
        emit(const UnauthenticatedState());
        return;
      }
      AppLogger.w('[AuthBloc] SignInWithGoogle failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
    }, (user) => _emitStateForUser(emit, user));
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymouslyEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.signInAnonymously();
    result.fold((failure) {
      AppLogger.w('[AuthBloc] SignInAnonymously failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
    }, (user) => _emitStateForUser(emit, user));
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
          add(PhoneCodeSentInternalEvent(verificationId, resendToken));
        },
        onVerificationFailed: (AuthFailure failure) {
          add(PhoneVerificationFailedInternalEvent(failure));
        },
        onVerificationCompleted: (AuthUser user) {
          add(AuthStateChangedEvent(user));
        },
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        '[AuthBloc] verify phone number failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const AuthErrorState('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignInWithSmsCode(
    SignInWithSmsCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.signInWithSmsCode(
      verificationId: event.verificationId,
      smsCode: event.smsCode,
    );
    result.fold((failure) {
      AppLogger.w('[AuthBloc] SignInWithSmsCode failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
    }, (user) => _emitStateForUser(emit, user));
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());
    final result = await _repository.signOut();
    result.fold((failure) {
      AppLogger.e('[AuthBloc] SignOut failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
    }, (_) => emit(const UnauthenticatedState()));
  }

  Future<void> _onSendEmailVerification(
    SendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    AppLogger.i('[AuthBloc] Requesting email verification send...');
    final result = await _repository.sendEmailVerification();

    await result.fold(
      (failure) async {
        AppLogger.e(
          '[AuthBloc] SendEmailVerification failed: ${failure.message}',
        );
        emit(AuthErrorState(failure.message));
        await _emitStateForCurrentUserSafely(emit, reload: false);
      },
      (_) async {
        AppLogger.i('[AuthBloc] Email verification sent successfully.');

        // Extract known user from state if possible to avoid async race condition
        AuthUser? user;
        if (state is AuthenticatedState) {
          user = (state as AuthenticatedState).user;
        } else if (state is EmailVerificationRequiredState) {
          user = (state as EmailVerificationRequiredState).user;
        }

        if (user == null) {
          final res = await _repository.getCurrentUser();
          user = res.fold((l) => null, (r) => r);
        }

        if (user != null) {
          emit(EmailVerificationSentState(user: user));
        } else {
          emit(
            const AuthErrorState('User not found after sending verification.'),
          );
          return;
        }

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await _emitStateForCurrentUserSafely(emit, reload: true);
      },
    );
  }

  Future<void> _onRefreshCurrentUser(
    RefreshCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.isSilent) {
      emit(const AuthLoadingState());
    }
    AppLogger.d(
      '[AuthBloc] Refreshing current user (silent: ${event.isSilent})',
    );
    final result = await _repository.reloadCurrentUser();
    result.fold((failure) {
      AppLogger.w('[AuthBloc] Refresh failed: ${failure.message}');
      emit(AuthErrorState(failure.message));
      _emitStateForCurrentUserSafely(emit, reload: false);
    }, (user) => _emitStateForUser(emit, user));
  }

  Future<void> _onSendPasswordReset(
    SendPasswordResetEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    AppLogger.i(
      '[AuthBloc] Requesting password reset email for: ${event.email}',
    );
    final result = await _repository.sendPasswordResetEmail(email: event.email);
    result.fold(
      (failure) {
        AppLogger.e('[AuthBloc] SendPasswordReset failed: ${failure.message}');
        emit(AuthErrorState(failure.message));
      },
      (_) {
        AppLogger.i('[AuthBloc] Password reset email sent successfully.');
        emit(const PasswordResetSentState());
        _emitStateForCurrentUserSafely(emit, reload: false);
      },
    );
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayNameEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _repository.updateDisplayName(name: event.name);
    result.fold(
      (failure) {
        AppLogger.e('[AuthBloc] UpdateDisplayName failed: ${failure.message}');
        emit(AuthErrorState(failure.message));
      },
      (_) async {
        emit(DisplayNameUpdatedState(event.name));
        await _emitStateForCurrentUser(emit, reload: true);
      },
    );
  }

  Future<void> _onUpdatePassword(
    UpdatePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _repository.updatePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) {
        AppLogger.e('[AuthBloc] UpdatePassword failed: ${failure.message}');
        emit(AuthErrorState(failure.message));
      },
      (_) {
        emit(const PasswordUpdatedState());
        add(const SignOutEvent());
      },
    );
  }

  void _subscribeToAuthStateChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _repository.authStateChanges.listen((user) {
      add(AuthStateChangedEvent(user));
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
    final result =
        reload
            ? await _repository.reloadCurrentUser()
            : await _repository.getCurrentUser();
    result.fold((failure) {
      AppLogger.w(
        '[AuthBloc] Failed to fetch current user: ${failure.message}',
      );
      emit(const UnauthenticatedState());
    }, (user) => _emitStateForUser(emit, user));
  }

  Future<void> _emitStateForCurrentUserSafely(
    Emitter<AuthState> emit, {
    required bool reload,
  }) async {
    try {
      await _emitStateForCurrentUser(emit, reload: reload);
    } catch (error) {
      AppLogger.w(
        '[AuthBloc] Failed to evaluate current user state',
        error: error,
      );
    }
  }
}
