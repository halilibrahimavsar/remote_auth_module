// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/pages/prisma/prisma_login_page.dart';
import 'package:remote_auth_module/src/presentation/pages/prisma/prisma_register_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Drop-in auth flow using the Prisma (geometric glassmorphism) theme.
class PrismaAuthFlow extends StatelessWidget {
  const PrismaAuthFlow({
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
        child: _PrismaFlowGate(
          authenticatedBuilder: authenticatedBuilder,
          config: config,
        ),
      );
    }
    return _PrismaFlowGate(
      authenticatedBuilder: authenticatedBuilder,
      config: config,
    );
  }
}

class _PrismaFlowGate extends StatefulWidget {
  const _PrismaFlowGate({
    required this.authenticatedBuilder,
    required this.config,
  });

  final Widget Function(BuildContext context, AuthUser user)
  authenticatedBuilder;
  final AuthTemplateConfig config;

  @override
  State<_PrismaFlowGate> createState() => _PrismaFlowGateState();
}

class _PrismaFlowGateState extends State<_PrismaFlowGate> {
  AuthState? _lastContentState;

  static const _prismaDark = Color(0xFF111111);

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
            backgroundColor: Color(0xFFF0F4F8),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_prismaDark),
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

        return PrismaLoginPage(
          config: widget.config,
          onRegisterTap:
              widget.config.showRegister
                  ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => BlocProvider.value(
                              value: context.read<AuthBloc>(),
                              child: PrismaRegisterPage(
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
                              child: const _PrismaForgotPasswordPage(),
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

/// Minimal forgot password page matching Prisma aesthetic.
class _PrismaForgotPasswordPage extends StatefulWidget {
  const _PrismaForgotPasswordPage();

  @override
  State<_PrismaForgotPasswordPage> createState() =>
      _PrismaForgotPasswordPageState();
}

class _PrismaForgotPasswordPageState extends State<_PrismaForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late AnimationController _blobController;

  static const _prismaDark = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _blobController.dispose();
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
        backgroundColor: const Color(0xFFF0F4F8),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Blobs Background
            AnimatedBuilder(
              animation: _blobController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BlobPainter(progress: _blobController.value),
                  size: Size.infinite,
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: _prismaDark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 40,
                                  sigmaY: 40,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Reset Password',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _prismaDark,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Enter your email to receive a secure reset link.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      _PrismaTextFieldInternal(
                                        controller: _emailController,
                                        label: 'Email address',
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: _prismaDark,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _prismaDark.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
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
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Send Reset Link',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.5,
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

class _PrismaTextFieldInternal extends StatefulWidget {
  const _PrismaTextFieldInternal({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  State<_PrismaTextFieldInternal> createState() =>
      _PrismaTextFieldInternalState();
}

class _PrismaTextFieldInternalState extends State<_PrismaTextFieldInternal> {
  bool _focused = false;
  static const _prismaDark = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _focused ? 0.9 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _focused
                  ? _prismaDark.withValues(alpha: 0.1)
                  : Colors.transparent,
          width: 1.5,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            color: _prismaDark,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: _prismaDark,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;
    final w = size.width;
    final h = size.height;

    // Draw 3 large blurry blobs
    _drawBlob(
      canvas,
      center: Offset(w * (0.2 + 0.3 * sin(t)), h * (0.2 + 0.2 * cos(t * 1.3))),
      radius: w * 0.7,
      color: const Color(0xFFFF2A5F).withValues(alpha: 0.15),
    );

    _drawBlob(
      canvas,
      center: Offset(
        w * (0.8 + 0.2 * cos(t * 0.8)),
        h * (0.4 + 0.3 * sin(t * 1.1)),
      ),
      radius: w * 0.8,
      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
    );

    _drawBlob(
      canvas,
      center: Offset(
        w * (0.5 + 0.4 * sin(t * 0.5)),
        h * (0.8 + 0.2 * cos(t * 0.9)),
      ),
      radius: w * 0.6,
      color: const Color(0xFFFFD700).withValues(alpha: 0.12),
    );
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint =
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
