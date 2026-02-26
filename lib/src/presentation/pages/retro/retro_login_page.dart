// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

/// Premium Retro-themed login page.
/// Inspired by synthwave and 80s arcade aesthetics.
/// Features a scrolling 3D grid, neon flickering, and glitch effects.
class RetroLoginPage extends StatefulWidget {
  const RetroLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<RetroLoginPage> createState() => _RetroLoginPageState();
}

class _RetroLoginPageState extends State<RetroLoginPage>
    with TickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final RememberMeService _rememberMeService = RememberMeService();

  late final AnimationController _bgController;
  late final AnimationController _glitchController;
  late final AnimationController _flickerController;

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _didPushVerificationPage = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberMe();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  Future<void> _loadRememberMe() async {
    final value = await _rememberMeService.load();
    if (mounted) {
      setState(() => _rememberMe = value);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _glitchController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0221), // Deep space purple
          body: Stack(
            children: [
              // Retro Synthwave Grid
              _RetroScrollingGrid(controller: _bgController),

              // Neon Sun/Horizon
              _RetroHorizon(),

              // Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _RetroGlassContainer(
                        flickerController: _flickerController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTitle(),
                            const SizedBox(height: 32),
                            if (errorMessage != null) ...[
                              _RetroErrorBanner(message: errorMessage),
                              const SizedBox(height: 24),
                            ],
                            _RetroField(
                              controller: _emailController,
                              label: 'IDENT_PRIMARY',
                              placeholder: 'ENTER_EMAIL...',
                            ),
                            const SizedBox(height: 20),
                            _RetroField(
                              controller: _passwordController,
                              label: 'IDENT_SECURE',
                              placeholder: 'ENTER_PASS...',
                              obscureText: _obscurePassword,
                              suffix: GestureDetector(
                                onTap:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                child: Text(
                                  _obscurePassword ? '[SHOW]' : '[HIDE]',
                                  style: const TextStyle(
                                    color: Color(0xFF00FFFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildOptions(),
                            const SizedBox(height: 40),
                            _RetroMainButton(
                              label: 'INITIATE_SESSION',
                              onPressed: _handleSignIn,
                              isLoading: isLoading,
                            ),
                            if (widget.config.showGoogleSignIn) ...[
                              const SizedBox(height: 16),
                              _RetroSocialButton(
                                label: 'LINK_G_CORE',
                                onPressed: _handleGoogleSignIn,
                              ),
                            ],
                            const SizedBox(height: 32),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // CRT Scanlines & TV Noise
              const _RetroTVOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        final offset = (_glitchController.value * 3) - 1.5;
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.config.loginTitle.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFFFF00FF).withValues(alpha: 0.5),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                ),
                Positioned(
                  left: offset,
                  child: Text(
                    widget.config.loginTitle.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                ),
                Text(
                  widget.config.loginTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'TERMINAL_OVERRIDE_ACTIVE',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        if (widget.config.showRememberMe)
          GestureDetector(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00FFFF),
                      width: 2,
                    ),
                    color:
                        _rememberMe
                            ? const Color(0xFF00FFFF)
                            : Colors.transparent,
                  ),
                  child:
                      _rememberMe
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.black,
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PERSIST_ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (widget.config.showForgotPassword &&
            widget.onForgotPasswordTap != null)
          GestureDetector(
            onTap: widget.onForgotPasswordTap,
            child: const Text(
              'RECOVER_KEY',
              style: TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 10,
                fontFamily: 'monospace',
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return widget.config.showRegister && widget.onRegisterTap != null
        ? GestureDetector(
          onTap: widget.onRegisterTap,
          child: const Text(
            '>> NEW_PILOT?_REGISTER_UNIT <<',
            style: TextStyle(
              color: Color(0xFFFFFF00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        )
        : const SizedBox.shrink();
  }

  void _handleStateChange(BuildContext context, AuthState state) {
    if (state is AuthenticatedState) return;
    if (state is EmailVerificationRequiredState && !_didPushVerificationPage) {
      _didPushVerificationPage = true;
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder:
                  (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: EmailVerificationPage(user: state.user),
                  ),
            ),
          )
          .whenComplete(() => _didPushVerificationPage = false);
    }
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    await _rememberMeService.save(value: _rememberMe);
    if (!mounted) return;
    context.read<AuthBloc>().add(
      SignInWithEmailEvent(email: email, password: password),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await _rememberMeService.save(value: _rememberMe);
    if (!mounted) return;
    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
  }
}

class _RetroScrollingGrid extends StatelessWidget {
  const _RetroScrollingGrid({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(painter: _GridPainter(progress: controller.value));
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF00FFFF).withValues(alpha: 0.15)
          ..strokeWidth = 1.0;

    final vanishingPoint = Offset(size.width / 2, size.height * 0.4);

    // Vertical lines
    for (var i = -10; i <= 10; i++) {
      final xStart = vanishingPoint.dx + (i * 40);
      canvas.drawLine(vanishingPoint, Offset(xStart, size.height), paint);
    }

    // Horizontal lines (scrolling)
    final lineCount = 15;
    for (var i = 0; i < lineCount; i++) {
      final t = (i + progress) / lineCount;
      final y = vanishingPoint.dy + (size.height - vanishingPoint.dy) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}

class _RetroHorizon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0221),
              const Color(0xFFFF00FF).withValues(alpha: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroGlassContainer extends StatelessWidget {
  const _RetroGlassContainer({
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
            color: Colors.black.withValues(alpha: 0.8),
            border: Border.all(
              color: const Color(0xFFFF00FF).withValues(alpha: flicker),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF00FF).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              const BoxShadow(color: Color(0xFF00FFFF), offset: Offset(6, 6)),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: child,
        );
      },
    );
  }
}

class _RetroField extends StatelessWidget {
  const _RetroField({
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
            fontSize: 10,
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
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
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

class _RetroMainButton extends StatelessWidget {
  const _RetroMainButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF00FF00),
            boxShadow: const [
              BoxShadow(color: Color(0xFF00FFFF), offset: Offset(4, 4)),
            ],
          ),
          child: Center(
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
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
                        fontSize: 14,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _RetroSocialButton extends StatelessWidget {
  const _RetroSocialButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00FFFF), width: 2),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, color: Color(0xFF00FFFF), size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetroErrorBanner extends StatelessWidget {
  const _RetroErrorBanner({required this.message});
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
        'CRITICAL_ERROR: ${message.toUpperCase()}',
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

class _RetroTVOverlay extends StatelessWidget {
  const _RetroTVOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Scanlines
          CustomPaint(painter: _ScanPainter(), size: Size.infinite),
          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..strokeWidth = 1.0;

    for (var i = 0.0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) => false;
}
