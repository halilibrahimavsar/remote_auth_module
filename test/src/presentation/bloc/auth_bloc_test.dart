import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRememberMeService extends Mock implements RememberMeService {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockRememberMeService mockRememberMeService;
  late StreamController<AuthUser?> authStateController;

  const verifiedUser = AuthUser(
    id: 'user-verified',
    email: 'verified@test.com',
    isEmailVerified: true,
    providerIds: ['password'],
  );

  const unverifiedUser = AuthUser(
    id: 'user-unverified',
    email: 'unverified@test.com',
    isEmailVerified: false,
    providerIds: ['password'],
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockRememberMeService = MockRememberMeService();
    authStateController = StreamController<AuthUser?>();
    addTearDown(authStateController.close);

    when(() => mockRememberMeService.load()).thenAnswer((_) async => true);
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => mockAuthRepository.signOut(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockAuthRepository.reloadCurrentUser(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockAuthRepository.sendEmailVerification(),
    ).thenAnswer((_) async => const Right(unit));
  });

  group('AuthBloc', () {
    test('initial state is AuthInitialState', () {
      final bloc = AuthBloc(
        repository: mockAuthRepository,
        rememberMeService: mockRememberMeService,
      );

      expect(bloc.state, const AuthInitialState());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'initialize emits authenticated when remembered and session exists',
      build: () {
        when(
          () => mockAuthRepository.initializeSession(),
        ).thenAnswer((_) async => const Right(verifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const InitializeAuthEvent()),
      expect:
          () => const [AuthLoadingState(), AuthenticatedState(verifiedUser)],
      verify: (_) {
        verify(() => mockRememberMeService.load()).called(1);
        verify(() => mockAuthRepository.initializeSession()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'initialize signs out when remember-me is false',
      build: () {
        when(() => mockRememberMeService.load()).thenAnswer((_) async => false);

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const InitializeAuthEvent()),
      expect: () => const [AuthLoadingState(), UnauthenticatedState()],
      verify: (_) {
        verify(() => mockAuthRepository.signOut()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'email sign-in keeps unverified users in verification-required state',
      build: () {
        when(
          () => mockAuthRepository.signInWithEmailAndPassword(
            email: 'u@test.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => const Right(unverifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) {
        bloc.add(
          const SignInWithEmailEvent(email: 'u@test.com', password: 'password'),
        );
      },
      expect:
          () => const [
            AuthLoadingState(),
            EmailVerificationRequiredState(unverifiedUser),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'register triggers verification-required and auto sends verification email',
      build: () {
        when(
          () => mockAuthRepository.signUpWithEmailAndPassword(
            email: 'new@test.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => const Right(unverifiedUser));
        when(
          () => mockAuthRepository.reloadCurrentUser(),
        ).thenAnswer((_) async => const Right(unverifiedUser));

        when(
          () => mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Right(unverifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) {
        bloc.add(
          const RegisterWithEmailEvent(
            email: 'new@test.com',
            password: 'password',
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect:
          () => const [
            AuthLoadingState(),
            EmailVerificationRequiredState(unverifiedUser),
            EmailVerificationSentState(user: unverifiedUser),
            EmailVerificationRequiredState(unverifiedUser),
          ],
      verify: (_) {
        verify(() => mockAuthRepository.sendEmailVerification()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'refresh event authenticates verified users',
      build: () {
        when(
          () => mockAuthRepository.reloadCurrentUser(),
        ).thenAnswer((_) async => const Right(verifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const RefreshCurrentUserEvent()),
      expect:
          () => const [AuthLoadingState(), AuthenticatedState(verifiedUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'send verification failure emits error then preserves verification gate',
      build: () {
        when(
          () => mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Left(UnexpectedAuthFailure('error')));
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Right(unverifiedUser));
        when(
          () => mockAuthRepository.reloadCurrentUser(),
        ).thenAnswer((_) async => const Right(unverifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) {
        bloc.add(const SendEmailVerificationEvent());
      },
      expect:
          () => const [
            AuthErrorState('error'),
            EmailVerificationRequiredState(unverifiedUser),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'google cancel emits unauthenticated as non-fatal outcome',
      build: () {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const Left(GoogleSignInCancelledFailure()));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
      expect: () => const [AuthLoadingState(), UnauthenticatedState()],
    );

    blocTest<AuthBloc, AuthState>(
      'update password emits success then signs out',
      build: () {
        when(
          () => mockAuthRepository.updatePassword(
            currentPassword: 'old',
            newPassword: 'new',
          ),
        ).thenAnswer((_) async => const Right(unit));

        when(
          () => mockAuthRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act:
          (bloc) => bloc.add(
            const UpdatePasswordEvent(
              currentPassword: 'old',
              newPassword: 'new',
            ),
          ),
      expect:
          () => const [
            AuthLoadingState(),
            PasswordUpdatedState(),
            AuthLoadingState(),
            UnauthenticatedState(),
          ],
      verify: (_) {
        verify(() => mockAuthRepository.signOut()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'signInAnonymously emits authenticated on success',
      build: () {
        when(
          () => mockAuthRepository.signInAnonymously(),
        ).thenAnswer((_) async => const Right(verifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const SignInAnonymouslyEvent()),
      expect:
          () => const [AuthLoadingState(), AuthenticatedState(verifiedUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'verifyPhoneNumber triggers internal event on code sent',
      build: () {
        when(
          () => mockAuthRepository.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onVerificationFailed: any(named: 'onVerificationFailed'),
            onVerificationCompleted: any(named: 'onVerificationCompleted'),
          ),
        ).thenAnswer((invocation) async {
          final onCodeSent =
              invocation.namedArguments[#onCodeSent]
                  as void Function(String, int?);
          onCodeSent('v-id', 123);
        });

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act:
          (bloc) =>
              bloc.add(const VerifyPhoneNumberEvent(phoneNumber: '+123456789')),
      expect:
          () => const [
            AuthLoadingState(),
            PhoneCodeSentState(verificationId: 'v-id', resendToken: 123),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'signInWithSmsCode emits authenticated on success',
      build: () {
        when(
          () => mockAuthRepository.signInWithSmsCode(
            verificationId: any(named: 'verificationId'),
            smsCode: any(named: 'smsCode'),
          ),
        ).thenAnswer((_) async => const Right(verifiedUser));

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act:
          (bloc) => bloc.add(
            const SignInWithSmsCodeEvent(
              verificationId: 'v-id',
              smsCode: '123456',
            ),
          ),
      expect:
          () => const [AuthLoadingState(), AuthenticatedState(verifiedUser)],
    );
  });
}
