import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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
    when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => null);
    when(
      () => mockAuthRepository.reloadCurrentUser(),
    ).thenAnswer((_) async => null);
    when(
      () => mockAuthRepository.sendEmailVerification(),
    ).thenAnswer((_) async {});
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
        ).thenAnswer((_) async => verifiedUser);

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
      expect: () => [const AuthLoadingState(), const UnauthenticatedState()],
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
        ).thenAnswer((_) async => unverifiedUser);

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
        ).thenAnswer((_) async => unverifiedUser);
        when(
          () => mockAuthRepository.reloadCurrentUser(),
        ).thenAnswer((_) async => unverifiedUser);

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
      wait: const Duration(milliseconds: 150),
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
        ).thenAnswer((_) async => verifiedUser);

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
        ).thenThrow(const TooManyRequestsException());
        when(
          () => mockAuthRepository.reloadCurrentUser(),
        ).thenAnswer((_) async => unverifiedUser);

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) {
        bloc.add(const SendEmailVerificationEvent());
        // This line was incorrectly placed in the original instruction.
        // It's not part of the blocTest structure as provided.
        // If it was intended to be an event, it should be added to the bloc.
        // If it was intended to be a state, it should be in the expect list.
        // Given the context of "send verification failure", adding a success state here
        // would contradict the test's purpose.
        // Therefore, it's omitted as it doesn't fit the test's logic or blocTest syntax.
      },
      expect:
          () => const [
            AuthErrorState('Too many requests. Please try again later.'),
            EmailVerificationRequiredState(unverifiedUser),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'google cancel emits unauthenticated as non-fatal outcome',
      build: () {
        when(
          () => mockAuthRepository.signInWithGoogle(),
        ).thenThrow(const GoogleSignInCancelledException());

        return AuthBloc(
          repository: mockAuthRepository,
          rememberMeService: mockRememberMeService,
        );
      },
      act: (bloc) => bloc.add(const SignInWithGoogleEvent()),
      expect: () => [const AuthLoadingState(), const UnauthenticatedState()],
    );

    blocTest<AuthBloc, AuthState>(
      'update password emits success then signs out',
      build: () {
        when(
          () => mockAuthRepository.updatePassword(
            currentPassword: 'old',
            newPassword: 'new',
          ),
        ).thenAnswer((_) async {});

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
          () => [
            const PasswordUpdatedState(),
            const AuthLoadingState(),
            const UnauthenticatedState(),
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
        ).thenAnswer((_) async => verifiedUser);

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
          () => [
            const AuthLoadingState(),
            const PhoneCodeSentState(verificationId: 'v-id', resendToken: 123),
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
        ).thenAnswer((_) async => verifiedUser);

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
