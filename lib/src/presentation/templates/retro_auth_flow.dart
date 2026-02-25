// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/forgot_password_page.dart';
import 'package:remote_auth_module/src/presentation/pages/retro/retro_login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/retro/retro_register_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Retro-themed auth flow. 8-bit aesthetic and CRT effects.
class RetroAuthFlow extends StatelessWidget {
  const RetroAuthFlow({
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
        child: _RetroFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }
    return _RetroFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _RetroFlowGate extends StatefulWidget {
  const _RetroFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });

  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_RetroFlowGate> createState() => _RetroFlowGateState();
}

class _RetroFlowGateState extends State<_RetroFlowGate> {
  AuthState? _lastContentState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        if (current is AuthErrorState) return true;
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is! AuthInitialState && state is! AuthLoadingState) {
          _lastContentState = state;
        }

        if (state is AuthInitialState) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: Text(
                'LOADING...',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

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

        return RetroLoginPage(
          config: widget.config,
          onRegisterTap:
              widget.config.showRegister
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: RetroRegisterPage(
                                config: widget.config,
                                onLoginTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                      ),
                    );
                  }
                  : null,
          onForgotPasswordTap:
              widget.config.showForgotPassword
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: const ForgotPasswordPage(),
                            ),
                      ),
                    );
                  }
                  : null,
        );
      },
    );
  }
}
