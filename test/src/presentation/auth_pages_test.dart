import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializeAuthEvent());
    registerFallbackValue(const AuthInitialState());
  });

  group('Auth pages', () {
    late MockAuthBloc bloc;
    late StreamController<AuthState> stateController;

    const unverifiedUser = AuthUser(
      id: 'u-1',
      email: 'u@test.com',
      isEmailVerified: false,
      providerIds: ['password'],
    );

    const verifiedUser = AuthUser(
      id: 'u-1',
      email: 'u@test.com',
      isEmailVerified: true,
      providerIds: ['password'],
    );

    setUp(() {
      bloc = MockAuthBloc();
      stateController = StreamController<AuthState>.broadcast();
      when(() => bloc.state).thenReturn(const UnauthenticatedState());
      whenListen(
        bloc,
        stateController.stream,
        initialState: const UnauthenticatedState(),
      );
      when(() => bloc.add(any())).thenReturn(null);
    });

    tearDown(() async {
      await stateController.close();
    });

    testWidgets(
      'RegisterPage calls onVerificationRequired before onAuthenticated',
      (tester) async {
        AuthUser? verificationUser;
        AuthUser? authenticatedUser;

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: bloc,
            child: MaterialApp(
              home: RegisterPage(
                onVerificationRequired: (user) => verificationUser = user,
                onAuthenticated: (user) => authenticatedUser = user,
              ),
            ),
          ),
        );

        stateController.add(EmailVerificationRequiredState(unverifiedUser));
        await tester.pumpAndSettle();

        expect(verificationUser, isNotNull);
        expect(verificationUser!.id, unverifiedUser.id);
        expect(authenticatedUser, isNull);

        stateController.add(AuthenticatedState(verifiedUser));
        await tester.pumpAndSettle();

        expect(authenticatedUser, isNotNull);
        expect(authenticatedUser!.id, verifiedUser.id);
      },
    );

    testWidgets('LoginPage calls onVerificationRequired for unverified user', (
      tester,
    ) async {
      AuthUser? callbackUser;

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: LoginPage(
              onVerificationRequired: (user) => callbackUser = user,
            ),
          ),
        ),
      );

      stateController.add(EmailVerificationRequiredState(unverifiedUser));
      await tester.pumpAndSettle();

      expect(callbackUser, isNotNull);
      expect(callbackUser!.id, unverifiedUser.id);
    });

    testWidgets('EmailVerificationPage dispatches resend and refresh events', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(EmailVerificationRequiredState(unverifiedUser));

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const MaterialApp(
            home: EmailVerificationPage(user: unverifiedUser),
          ),
        ),
      );

      await tester.tap(find.text('Resend email'));
      await tester.pump();

      verify(() => bloc.add(const SendEmailVerificationEvent())).called(1);

      await tester.tap(find.text('Refresh Status'));
      await tester.pump();

      verify(() => bloc.add(const RefreshCurrentUserEvent())).called(1);

      stateController.add(EmailVerificationSentState(user: unverifiedUser));
      await tester.pump();

      expect(find.textContaining('Resend in'), findsOneWidget);
    });
  });
}
