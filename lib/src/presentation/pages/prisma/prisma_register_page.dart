// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/presentation/widgets/phone_auth_dialog.dart';

class PrismaRegisterPage extends StatefulWidget {
  const PrismaRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<PrismaRegisterPage> createState() => _PrismaRegisterPageState();
}

class _PrismaRegisterPageState extends State<PrismaRegisterPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _entranceController;
  late AnimationController _blobController;

  static const _prismaDark = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    Future.delayed(
      const Duration(milliseconds: 50),
      () => _entranceController.forward(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entranceController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      RegisterWithEmailEvent(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  void _handleStateChange(BuildContext context, AuthState state) {
    if (state is AuthErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state is EmailVerificationSentState ||
        state is EmailVerificationRequiredState) {
      if (mounted && widget.onLoginTap != null) {
        widget.onLoginTap!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;

        return Scaffold(
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

              // Content Layout
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.config.logo != null) ...[
                            _springEntrance(0, child: widget.config.logo!),
                            const SizedBox(height: 32),
                          ],
                          _springEntrance(1, child: _buildHeader()),
                          const SizedBox(height: 40),
                          _springEntrance(
                            2,
                            child: _buildGlassCard(isLoading, context),
                          ),
                          const SizedBox(height: 32),
                          _springEntrance(6, child: _buildBottomLinks(context)),
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

  Widget _buildBottomLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onLoginTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Sign in',
              style: TextStyle(
                color: _prismaDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(bool isLoading, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.65,
        ), // High opacity for frosted effect
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
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(),
                const SizedBox(height: 32),
                _springEntrance(
                  4,
                  child: _buildSignUpButton(isLoading, context),
                ),
                if (widget.config.showGoogleSignIn ||
                    widget.config.showPhoneSignIn ||
                    widget.config.showAnonymousSignIn) ...[
                  const SizedBox(height: 32),
                  _springEntrance(5, child: _buildSocialSection(context)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          widget.config.registerTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _prismaDark,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.config.registerSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.5),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _PrismaTextField(
          controller: _emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _PrismaTextField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 20),
        _PrismaTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildSignUpButton(bool isLoading, BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _prismaDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _prismaDark.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _handleRegister(context),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                    : const Text(
                      'Create Account',
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
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.black.withValues(alpha: 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or register with',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.config.showGoogleSignIn)
              Expanded(
                child: _PrismaSocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  onTap:
                      () => context.read<AuthBloc>().add(
                        const SignInWithGoogleEvent(),
                      ),
                ),
              ),
            if (widget.config.showGoogleSignIn &&
                (widget.config.showPhoneSignIn ||
                    widget.config.showAnonymousSignIn))
              const SizedBox(width: 16),
            if (widget.config.showPhoneSignIn)
              Expanded(
                child: _PrismaSocialButton(
                  icon: Icons.phone_android,
                  label: 'Phone',
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder:
                          (_) => BlocProvider.value(
                            value: context.read<AuthBloc>(),
                            child: const PhoneAuthDialog(),
                          ),
                    );
                  },
                ),
              ),
            if (!widget.config.showGoogleSignIn &&
                !widget.config.showPhoneSignIn &&
                widget.config.showAnonymousSignIn)
              Expanded(
                child: _PrismaSocialButton(
                  icon: Icons.person_outline,
                  label: 'Guest',
                  onTap:
                      () => context.read<AuthBloc>().add(
                        const SignInAnonymouslyEvent(),
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _springEntrance(int index, {required Widget child}) {
    final delay = (index * 0.08).clamp(0.0, 0.5);
    final end = (delay + 0.5).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, end, curve: Curves.elasticOut),
    );

    final fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, delay + 0.2, curve: Curves.easeIn),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _PrismaTextField extends StatefulWidget {
  const _PrismaTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_PrismaTextField> createState() => _PrismaTextFieldState();
}

class _PrismaTextFieldState extends State<_PrismaTextField> {
  bool _focused = false;
  bool _isPasswordVisible = false;
  static const _prismaDark = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
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
              obscureText: widget.obscureText && !_isPasswordVisible,
              keyboardType: widget.keyboardType,
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
                suffixIcon:
                    widget.obscureText
                        ? IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.black.withValues(alpha: 0.3),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        )
                        : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrismaSocialButton extends StatelessWidget {
  const _PrismaSocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF111111), size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
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
