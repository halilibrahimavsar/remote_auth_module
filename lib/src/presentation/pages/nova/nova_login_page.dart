// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';

import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

class NovaLoginPage extends StatefulWidget {
  const NovaLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<NovaLoginPage> createState() => _NovaLoginPageState();
}

class _NovaLoginPageState extends State<NovaLoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _entranceController;
  late AnimationController _starController;

  static const _novaAccent = Color(0xFFF8B500); // Bright gold
  static const _novaDark = Color(0xFF0F0C29); // Deep space indigo

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    Future.delayed(
      const Duration(milliseconds: 100),
      () => _entranceController.forward(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _handleSignIn(BuildContext context) {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter email and password'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
      SignInWithEmailEvent(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: Colors.black,
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

              // Animated Starfield
              AnimatedBuilder(
                animation: _starController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _StarfieldPainter(progress: _starController.value),
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
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.config.logo != null) ...[
                            _staggered(0, child: widget.config.logo!),
                            const SizedBox(height: 32),
                          ],
                          _staggered(1, child: _buildHeader()),
                          const SizedBox(height: 48),
                          _staggered(
                            2,
                            child: _buildGlassCard(isLoading, context),
                          ),
                          if (widget.config.showRegister) ...[
                            const SizedBox(height: 24),
                            _staggered(6, child: _buildBottomLinks(context)),
                          ],
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
          'New roughly here?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
        TextButton(
          onPressed: widget.onRegisterTap,
          style: TextButton.styleFrom(
            foregroundColor: _novaAccent,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('JOIN NOW'),
        ),
      ],
    );
  }

  Widget _buildGlassCard(bool isLoading, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(),
                if (widget.config.showForgotPassword) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onForgotPasswordTap,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.5),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _staggered(4, child: _buildSignInButton(isLoading, context)),
                if (widget.config.showGoogleSignIn ||
                    widget.config.showPhoneSignIn ||
                    widget.config.showAnonymousSignIn) ...[
                  const SizedBox(height: 32),
                  _staggered(5, child: _buildSocialSection(context)),
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
          widget.config.loginTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.config.loginSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _NovaTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _NovaTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildSignInButton(bool isLoading, BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _novaAccent,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: _novaAccent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _handleSignIn(context),
          borderRadius: BorderRadius.circular(27),
          child: Center(
            child:
                isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'SIGN IN',
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
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.config.showGoogleSignIn)
              _NovaSocialButton(
                icon: Icons.g_mobiledata,
                onTap:
                    () => context.read<AuthBloc>().add(
                      const SignInWithGoogleEvent(),
                    ),
              ),
            if (widget.config.showGoogleSignIn &&
                (widget.config.showPhoneSignIn ||
                    widget.config.showAnonymousSignIn))
              const SizedBox(width: 16),
            if (widget.config.showPhoneSignIn)
              _NovaSocialButton(
                icon: Icons.phone_android,
                onTap: () {
                  // TODO: Phone auth
                },
              ),
            if (widget.config.showPhoneSignIn &&
                widget.config.showAnonymousSignIn)
              const SizedBox(width: 16),
            if (widget.config.showAnonymousSignIn)
              _NovaSocialButton(
                icon: Icons.person_outline,
                onTap:
                    () => context.read<AuthBloc>().add(
                      const SignInAnonymouslyEvent(),
                    ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final delay = (index * 0.1).clamp(0.0, 0.6);
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _NovaTextField extends StatefulWidget {
  const _NovaTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_NovaTextField> createState() => _NovaTextFieldState();
}

class _NovaTextFieldState extends State<_NovaTextField> {
  bool _focused = false;
  bool _isPasswordVisible = false;
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
                  obscureText: widget.obscureText && !_isPasswordVisible,
                  keyboardType: widget.keyboardType,
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
            if (widget.obscureText)
              IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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

class _NovaSocialButton extends StatefulWidget {
  const _NovaSocialButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NovaSocialButton> createState() => _NovaSocialButtonState();
}

class _NovaSocialButtonState extends State<_NovaSocialButton> {
  bool _hovering = false;
  static const _novaAccent = Color(0xFFF8B500);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _hovering
                    ? _novaAccent.withValues(alpha: 0.1)
                    : Colors.transparent,
            border: Border.all(
              color:
                  _hovering
                      ? _novaAccent
                      : Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color:
                _hovering ? _novaAccent : Colors.white.withValues(alpha: 0.7),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Deterministic stars
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        sqrt(size.width * size.width + size.height * size.height) / 2;

    for (var i = 0; i < 150; i++) {
      // Star properties
      final angle = rng.nextDouble() * 2 * pi;
      final distance = rng.nextDouble() * maxRadius;
      final sizeFactor = rng.nextDouble();

      // Rotation
      final currentAngle =
          angle + (progress * 2 * pi * 0.5); // 0.5 rev per cycle

      final x = center.dx + cos(currentAngle) * distance;
      final y = center.dy + sin(currentAngle) * distance;

      // Twinkling
      final phase = rng.nextDouble() * 2 * pi;
      final twinkle = (sin(progress * 20 * pi + phase) + 1) / 2; // 0 to 1
      final alpha =
          (0.1 + (0.6 * twinkle)) * (1 - (distance / maxRadius) * 0.3);

      final color =
          i % 5 == 0
              ? const Color(0xFF00E5CC) // Occasional teal star
              : i % 7 == 0
              ? const Color(0xFFF8B500) // Occasional gold star
              : Colors.white;

      final paint =
          Paint()
            ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sizeFactor * 1.5);

      canvas.drawCircle(Offset(x, y), 0.5 + sizeFactor * 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
