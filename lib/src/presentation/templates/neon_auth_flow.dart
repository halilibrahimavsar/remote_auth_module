// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/neon/neon_login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/neon/neon_register_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Drop-in auth flow using the Neon (cyberpunk) theme.
///
/// Features neon glow borders, floating particles, typewriter title animation,
/// and focus-reactive fields on a pure-black canvas.
class NeonAuthFlow extends StatelessWidget {
  const NeonAuthFlow({
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
        child: _NeonFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }
    return _NeonFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _NeonFlowGate extends StatefulWidget {
  const _NeonFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });

  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_NeonFlowGate> createState() => _NeonFlowGateState();
}

class _NeonFlowGateState extends State<_NeonFlowGate> {
  AuthState? _lastContentState;

  static const _neonBlue = Color(0xFF00D4FF);

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
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_neonBlue),
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

        return NeonLoginPage(
          config: widget.config,
          onRegisterTap:
              widget.config.showRegister
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: NeonRegisterPage(
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
                              child: const _NeonForgotPasswordPage(),
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

/// Minimal forgot password page matching Neon aesthetic.
class _NeonForgotPasswordPage extends StatefulWidget {
  const _NeonForgotPasswordPage();

  @override
  State<_NeonForgotPasswordPage> createState() =>
      _NeonForgotPasswordPageState();
}

class _NeonForgotPasswordPageState extends State<_NeonForgotPasswordPage> {
  final _emailController = TextEditingController();

  static const _neonBlue = Color(0xFF00D4FF);

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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: _neonBlue.withValues(alpha: 0.8)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'RESET PASSWORD',
                style: TextStyle(
                  color: _neonBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: _neonBlue, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive a reset link.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF0D0D0D),
                  border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'EMAIL',
                    labelStyle: TextStyle(
                      color: _neonBlue.withValues(alpha: 0.5),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _neonBlue.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _neonBlue,
                  boxShadow: [
                    BoxShadow(
                      color: _neonBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'SEND RESET LINK',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
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
