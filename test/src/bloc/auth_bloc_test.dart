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
      wait: const Duration(milliseconds: 10),
      expect:
          () => const [
            AuthLoadingState(),
            EmailVerificationRequiredState(unverifiedUser),
            EmailVerificationSentState(),
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
      act: (bloc) => bloc.add(const SendEmailVerificationEvent()),
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
  });
}
