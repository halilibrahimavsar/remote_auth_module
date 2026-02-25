// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/nova/nova_login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/nova/nova_register_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Drop-in auth flow using the Nova (space/starry) theme.
class NovaAuthFlow extends StatelessWidget {
  const NovaAuthFlow({
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
        child: _NovaFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }
    return _NovaFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _NovaFlowGate extends StatefulWidget {
  const _NovaFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });

  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_NovaFlowGate> createState() => _NovaFlowGateState();
}

class _NovaFlowGateState extends State<_NovaFlowGate> {
  AuthState? _lastContentState;

  static const _novaAccent = Color(0xFFF8B500);
  static const _novaDark = Color(0xFF0F0C29);

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
            backgroundColor: _novaDark,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_novaAccent),
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

        return NovaLoginPage(
          config: widget.config,
          onRegisterTap:
              widget.config.showRegister
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: NovaRegisterPage(
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
                              child: const _NovaForgotPasswordPage(),
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

/// Minimal forgot password page matching Nova aesthetic.
class _NovaForgotPasswordPage extends StatefulWidget {
  const _NovaForgotPasswordPage();

  @override
  State<_NovaForgotPasswordPage> createState() =>
      _NovaForgotPasswordPageState();
}

class _NovaForgotPasswordPageState extends State<_NovaForgotPasswordPage> {
  final _emailController = TextEditingController();

  static const _novaAccent = Color(0xFFF8B500);
  static const _novaDark = Color(0xFF0F0C29);

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
        backgroundColor: Colors.black, // Match underlying scaffold color
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [_novaDark, Colors.black],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Reset Password',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Enter your email to receive a reset link.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _NovaTextFieldInternal(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _novaAccent,
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        final email =
                                            _emailController.text.trim();
                                        if (email.isNotEmpty) {
                                          context.read<AuthBloc>().add(
                                            SendPasswordResetEvent(
                                              email: email,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(27),
                                      child: const Center(
                                        child: Text(
                                          'SEND RESET LINK',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Internal copy of the text field to keep the forgot password page self-contained
class _NovaTextFieldInternal extends StatefulWidget {
  const _NovaTextFieldInternal({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  State<_NovaTextFieldInternal> createState() => _NovaTextFieldInternalState();
}

class _NovaTextFieldInternalState extends State<_NovaTextFieldInternal> {
  bool _focused = false;
  static const _novaAccent = Color(0xFFF8B500);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color:
                  _focused ? _novaAccent : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Focus(
                onFocusChange: (f) => setState(() => _focused = f),
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: _novaAccent,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: TextStyle(
                      color:
                          _focused
                              ? _novaAccent
                              : Colors.white.withValues(alpha: 0.5),
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: _novaAccent,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 1,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.2),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: _focused ? 2 : 1,
            width: _focused ? 400 : 0,
            color: _novaAccent,
          ),
        ),
      ],
    );
  }
}
