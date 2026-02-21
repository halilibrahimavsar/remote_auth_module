import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/forgot_password_page.dart';
import 'package:remote_auth_module/src/presentation/pages/login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/register_page.dart';

/// A drop-in, ready-to-use template that manages the entire authentication flow.
///
/// This component automatically switches between loading screens, login/registration UI,
/// email verification, and the main app content based on the [AuthState].
///
/// It supports custom DI and BLoC provisioning:
/// - If [authBloc] is provided, it will wrap the flow in a `BlocProvider.value`.
/// - If [authBloc] is null, it assumes an `AuthBloc` is already accessible
///   in the Widget tree via `context.read<AuthBloc>()`.
///
/// This makes it easy to integrate with packages like `get_it`, `injectable`,
/// or standard `Provider`.
///
/// Example usage with `get_it`:
/// ```dart
/// RemoteAuthFlow(
///   authBloc: GetIt.instance<AuthBloc>(),
///   authenticatedBuilder: (context, user) => MyHomePage(user: user),
/// )
/// ```
class RemoteAuthFlow extends StatelessWidget {
  final AuthBloc? authBloc;
  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final Widget? logo;
  final String loginTitle;
  final bool showGoogleSignIn;

  const RemoteAuthFlow({
    super.key,
    required this.authenticatedBuilder,
    this.authBloc,
    this.logo,
    this.loginTitle = 'Welcome Back',
    this.showGoogleSignIn = true,
  });

  @override
  Widget build(BuildContext context) {
    if (authBloc != null) {
      return BlocProvider.value(
        value: authBloc!,
        child: _AuthFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          logo: logo,
          loginTitle: loginTitle,
          showGoogleSignIn: showGoogleSignIn,
        ),
      );
    }

    return _AuthFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      logo: logo,
      loginTitle: loginTitle,
      showGoogleSignIn: showGoogleSignIn,
    );
  }
}

class _AuthFlowGate extends StatelessWidget {
  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final Widget? logo;
  final String loginTitle;
  final bool showGoogleSignIn;

  const _AuthFlowGate({
    required this.authenticatedBuilder,
    this.logo,
    required this.loginTitle,
    required this.showGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Only rebuild if the runtime type changes (e.g. Unauthenticated to Authenticated)
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is AuthInitialState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthenticatedState) {
          return authenticatedBuilder(context, state.user);
        }

        if (state is EmailVerificationRequiredState) {
          return EmailVerificationPage(user: state.user);
        }

        // Return LoginPage as default for UnauthenticatedState & AuthErrorState
        // LoginPage handles loading state visualization via AuthLoadingState internally.
        return LoginPage(
          logo: logo,
          title: loginTitle,
          showGoogleSignIn: showGoogleSignIn,
          onRegisterTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: RegisterPage(
                        onLoginTap: () => Navigator.of(context).pop(),
                      ),
                    ),
              ),
            );
          },
          onForgotPasswordTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: const ForgotPasswordPage(),
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
