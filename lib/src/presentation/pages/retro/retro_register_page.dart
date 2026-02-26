// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Premium Retro-themed register page.
class RetroRegisterPage extends StatefulWidget {
  const RetroRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<RetroRegisterPage> createState() => _RetroRegisterPageState();
}

class _RetroRegisterPageState extends State<RetroRegisterPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _bgController;
  late final AnimationController _flickerController;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0221),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF00FFFF),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              _RetroScrollingGridInternal(controller: _bgController),
              _RetroHorizonInternal(),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _RetroGlassFrame(
                      flickerController: _flickerController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NEW_USER_REGISTRATION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF00FF00),
                              fontFamily: 'monospace',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (errorMessage != null) ...[
                            _RetroAlertBanner(message: errorMessage),
                            const SizedBox(height: 24),
                          ],
                          _RetroInputBlock(
                            controller: _emailController,
                            label: 'USER_ID / EMAIL',
                            placeholder: 'USER@DOMAIN.COM',
                          ),
                          const SizedBox(height: 20),
                          _RetroInputBlock(
                            controller: _passwordController,
                            label: 'SECURE_KEY',
                            placeholder: '********',
                            obscureText: _obscurePassword,
                            suffix: GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                              child: Text(
                                _obscurePassword ? '[?]' : '[!]',
                                style: const TextStyle(
                                  color: Color(0xFFFFFF00),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _RetroInputBlock(
                            controller: _confirmPasswordController,
                            label: 'RE_IDENTIFY',
                            placeholder: '********',
                            obscureText: _obscureConfirm,
                          ),
                          const SizedBox(height: 40),
                          _RetroExecuteBtn(
                            label: 'COMMIT_REGISTRY',
                            onPressed: _handleRegister,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap:
                                widget.onLoginTap ??
                                () => Navigator.of(context).pop(),
                            child: const Text(
                              '<< ABORT_PROMPT_GOTO_LOGIN >>',
                              style: TextStyle(
                                color: Color(0xFF00FFFF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const _RetroTVNoiseOverlay(),
            ],
          ),
        );
      },
    );
  }

  void _handleRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('FAIL: PASS_MISMATCH')));
      return;
    }

    final error = AuthValidators.validatePassword(password);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('FAIL: $error')));
      return;
    }

    context.read<AuthBloc>().add(
      RegisterWithEmailEvent(email: email, password: password),
    );
  }
}

class _RetroGlassFrame extends StatelessWidget {
  const _RetroGlassFrame({
    required this.child,
    required this.flickerController,
  });
  final Widget child;
  final AnimationController flickerController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flickerController,
      builder: (context, _) {
        final flicker = flickerController.value > 0.8 ? 0.9 : 0.4;
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(
              color: const Color(0xFFFF00FF).withValues(alpha: flicker),
              width: 3,
            ),
            boxShadow: [
              const BoxShadow(color: Color(0xFF00FFFF), offset: Offset(5, 5)),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: child,
        );
      },
    );
  }
}

class _RetroInputBlock extends StatelessWidget {
  const _RetroInputBlock({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '> $label',
          style: const TextStyle(
            color: Color(0xFF00FF00),
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  cursorColor: const Color(0xFF00FF00),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetroExecuteBtn extends StatelessWidget {
  const _RetroExecuteBtn({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFF00),
          boxShadow: const [
            BoxShadow(color: Color(0xFF0000FF), offset: Offset(4, 4)),
          ],
        ),
        child: Center(
          child:
              isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _RetroScrollingGridInternal extends StatelessWidget {
  const _RetroScrollingGridInternal({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder:
            (context, _) => CustomPaint(
              painter: _GridPainterInternal(progress: controller.value),
            ),
      ),
    );
  }
}

class _GridPainterInternal extends CustomPainter {
  _GridPainterInternal({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF00FFFF).withValues(alpha: 0.12)
          ..strokeWidth = 1.0;

    final vanishingPoint = Offset(size.width / 2, size.height * 0.45);
    for (var i = -8; i <= 8; i++) {
      canvas.drawLine(
        vanishingPoint,
        Offset(vanishingPoint.dx + (i * 60), size.height),
        paint,
      );
    }
    final lineCount = 12;
    for (var i = 0; i < lineCount; i++) {
      final t = (i + progress) / lineCount;
      final y = vanishingPoint.dy + (size.height - vanishingPoint.dy) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainterInternal oldDelegate) => true;
}

class _RetroHorizonInternal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.45,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0221),
              const Color(0xFFFF00FF).withValues(alpha: 0.15),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroAlertBanner extends StatelessWidget {
  const _RetroAlertBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000).withValues(alpha: 0.2),
        border: Border.all(color: const Color(0xFFFF0000), width: 2),
      ),
      child: Text(
        'FAIL: ${message.toUpperCase()}',
        style: const TextStyle(
          color: Color(0xFFFF0000),
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RetroTVNoiseOverlay extends StatelessWidget {
  const _RetroTVNoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ScanPainterInternal(), size: Size.infinite),
    );
  }
}

class _ScanPainterInternal extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..strokeWidth = 1.0;
    for (var i = 0.0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanPainterInternal oldDelegate) => false;
}
