// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

/// Premium Zen-themed login page.
/// Features a "breathing" animated background, floating petals,
/// and smooth staggered animations.
class ZenLoginPage extends StatefulWidget {
  const ZenLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<ZenLoginPage> createState() => _ZenLoginPageState();
}

class _ZenLoginPageState extends State<ZenLoginPage>
    with TickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final RememberMeService _rememberMeService = RememberMeService();

  late final AnimationController _bgController;
  late final AnimationController _contentController;

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
      duration: const Duration(seconds: 10),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
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
    _contentController.dispose();
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
          backgroundColor: const Color(0xFFFBFBF8),
          body: Stack(
            children: [
              // Animated Background Level 1: Breathing Gradient
              _ZenBreathingBackground(controller: _bgController),

              // Animated Background Level 2: Floating Petals
              _ZenPetalsBackground(controller: _bgController),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 48),
                          _buildForm(errorMessage, isLoading),
                          const SizedBox(height: 32),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: Column(
          children: [
            if (widget.config.logo != null)
              widget.config.logo!
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B705C).withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 40,
                  color: Color(0xFF6B705C),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              widget.config.loginTitle,
              style: const TextStyle(
                color: Color(0xFF333533),
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.config.loginSubtitle,
              style: TextStyle(
                color: const Color(0xFF6B705C).withValues(alpha: 0.7),
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String? errorMessage, bool isLoading) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.6),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        ),
        child: Column(
          children: [
            if (errorMessage != null) ...[
              AuthStatusBanner(message: errorMessage),
              const SizedBox(height: 24),
            ],
            _ZenInput(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            _ZenInput(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B705C).withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptions(),
            const SizedBox(height: 40),
            _ZenMajorButton(
              label: 'Sign In',
              onPressed: _handleSignIn,
              isLoading: isLoading,
            ),
            if (widget.config.showGoogleSignIn) ...[
              const SizedBox(height: 16),
              _ZenGoogleButton(onPressed: _handleGoogleSignIn),
            ],
          ],
        ),
      ),
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          _rememberMe
                              ? const Color(0xFF6B705C)
                              : const Color(0xFF6B705C).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    color:
                        _rememberMe
                            ? const Color(0xFF6B705C)
                            : Colors.transparent,
                  ),
                  child:
                      _rememberMe
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Keep me signed in',
                  style: TextStyle(color: Color(0xFF6B705C), fontSize: 13),
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
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF6B705C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0),
      ),
      child:
          widget.config.showRegister && widget.onRegisterTap != null
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: const Color(0xFF6B705C).withValues(alpha: 0.6),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onRegisterTap,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF6B705C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
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

class _ZenInput extends StatelessWidget {
  const _ZenInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6B705C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6B705C).withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B705C).withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: const Color(0xFF6B705C),
            style: const TextStyle(color: Color(0xFF333533), fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 22,
                color: const Color(0xFF6B705C).withValues(alpha: 0.3),
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ZenMajorButton extends StatelessWidget {
  const _ZenMajorButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF6B705C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B705C).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _ZenGoogleButton extends StatelessWidget {
  const _ZenGoogleButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B705C).withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.g_mobiledata,
                size: 32,
                color: Color(0xFF6B705C),
              ),
              const SizedBox(width: 8),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFF6B705C),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenBreathingBackground extends StatelessWidget {
  const _ZenBreathingBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final sinVal = (math.sin(controller.value * 2 * math.pi) + 1) / 2;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.5 * math.cos(controller.value * 2 * math.pi),
                0.5 * math.sin(controller.value * 2 * math.pi),
              ),
              radius: 1.5 + (sinVal * 0.5),
              colors: [
                const Color(0xFFF1F3EB).withValues(alpha: 0.8),
                const Color(0xFFFBFBF8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ZenPetalsBackground extends StatelessWidget {
  const _ZenPetalsBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PetalsPainter(progress: controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _PetalsPainter extends CustomPainter {
  _PetalsPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF6B705C).withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final t = (progress + (i / 8)) % 1.0;
      final x = size.width * (0.1 + 0.8 * math.sin(i * 1.5 + t * 0.5));
      final y = size.height * (1.1 - (t * 1.2));
      final rotation = t * math.pi * 2 + (i * 0.5);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final path =
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(10, -15, 0, -30)
            ..quadraticBezierTo(-10, -15, 0, 0);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalsPainter oldDelegate) => true;
}
