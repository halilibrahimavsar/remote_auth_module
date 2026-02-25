// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/aurora/aurora_login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/aurora/aurora_register_page.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Drop-in replacement for [RemoteAuthFlow] that uses the Aurora theme.
///
/// Same API contract: provide [authenticatedBuilder] and optional [authBloc].
/// The Aurora template features animated mesh gradients, pulsing glass cards,
/// and staggered entrance animations.
class AuroraAuthFlow extends StatelessWidget {
  const AuroraAuthFlow({
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
        child: _AuroraFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }
    return _AuroraFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _AuroraFlowGate extends StatefulWidget {
  const _AuroraFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });

  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_AuroraFlowGate> createState() => _AuroraFlowGateState();
}

class _AuroraFlowGateState extends State<_AuroraFlowGate> {
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
            backgroundColor: Color(0xFF0B0E1A),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5CC)),
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

        return AuroraLoginPage(
          config: widget.config,
          onRegisterTap:
              widget.config.showRegister
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: AuroraRegisterPage(
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
                              child: const _AuroraForgotPasswordPage(),
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

/// Minimal forgot password page matching Aurora aesthetic.
class _AuroraForgotPasswordPage extends StatefulWidget {
  const _AuroraForgotPasswordPage();

  @override
  State<_AuroraForgotPasswordPage> createState() =>
      _AuroraForgotPasswordPageState();
}

class _AuroraForgotPasswordPageState extends State<_AuroraForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetSentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive a reset link.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: const Color(0xFF00E5CC).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5CC), Color(0xFF7B2FF7)],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final email = _emailController.text.trim();
                      if (email.isNotEmpty) {
                        context.read<AuthBloc>().add(
                          SendPasswordResetEvent(email: email),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Send Reset Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
