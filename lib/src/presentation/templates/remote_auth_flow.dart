// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/forgot_password_page.dart';
import 'package:remote_auth_module/src/presentation/pages/login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/register_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

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
  const RemoteAuthFlow({
    required this.authenticatedBuilder,
    this.authBloc,
    this.config = const AuthTemplateConfig(),
    super.key,
  });
  final AuthBloc? authBloc;
  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  Widget build(BuildContext context) {
    if (authBloc != null) {
      return BlocProvider.value(
        value: authBloc!,
        child: _AuthFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }

    return _AuthFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _AuthFlowGate extends StatefulWidget {
  const _AuthFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });
  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_AuthFlowGate> createState() => _AuthFlowGateState();
}

class _AuthFlowGateState extends State<_AuthFlowGate> {
  AuthState? _lastContentState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Rebuild if error occurred to show the message
        if (current is AuthErrorState) return true;
        // Only rebuild if the runtime type changes for other states
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        // Update last content state if it's not a transient state
        if (state is! AuthInitialState && state is! AuthLoadingState) {
          _lastContentState = state;
        }

        if (state is AuthInitialState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle loading state by showing the last known content instead of LoginPage
        final effectiveState =
            (state is AuthLoadingState && _lastContentState != null)
                ? _lastContentState!
                : state;

        if (effectiveState is AuthenticatedState) {
          return widget.authenticatedBuilder(context, effectiveState.user);
        }

        if (effectiveState is EmailVerificationRequiredState) {
          return EmailVerificationPage(user: effectiveState.user);
        }

        if (effectiveState is EmailVerificationSentState) {
          return EmailVerificationPage(user: effectiveState.user);
        }

        // Return LoginPage as default for UnauthenticatedState, AuthErrorState
        // or AuthLoadingState without prior content.
        return LoginPage(
          logo: widget.config.logo,
          title: widget.config.loginTitle,
          subtitle: widget.config.loginSubtitle,
          showGoogleSignIn: widget.config.showGoogleSignIn,
          showPhoneSignIn: widget.config.showPhoneSignIn,
          showAnonymousSignIn: widget.config.showAnonymousSignIn,
          showRememberMe: widget.config.showRememberMe,
          onRegisterTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: RegisterPage(
                        onLoginTap: () => Navigator.of(context).pop(),
                        title: widget.config.registerTitle,
                        subtitle: widget.config.registerSubtitle,
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
                      child: ForgotPasswordPage(title: 'Reset Password'),
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
