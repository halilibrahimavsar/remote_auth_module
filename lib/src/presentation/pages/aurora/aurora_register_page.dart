// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';

/// Aurora-themed registration page.
class AuroraRegisterPage extends StatefulWidget {
  const AuroraRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<AuroraRegisterPage> createState() => _AuroraRegisterPageState();
}

class _AuroraRegisterPageState extends State<AuroraRegisterPage>
    with TickerProviderStateMixin {
  late final AnimationController _auroraController;
  late final AnimationController _entranceController;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailVerificationRequiredState) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: const Color(0xFF0B0E1A),
          body: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _auroraController,
                builder:
                    (context, _) => CustomPaint(
                      painter: _AuroraRegisterPainter(
                        progress: _auroraController.value,
                      ),
                      size: Size.infinite,
                    ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 6,
                      left: 4,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: _buildCard(errorMessage),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E5CC),
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

  Widget _buildCard(String? errorMessage) {
    var index = 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _staggered(
                  index++,
                  child: Text(
                    widget.config.registerTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _staggered(
                  index++,
                  child: Text(
                    widget.config.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthStatusBanner(message: errorMessage),
                ],
                const SizedBox(height: 28),
                _staggered(
                  index++,
                  child: _AuroraRegisterField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 14),
                _staggered(
                  index++,
                  child: _AuroraRegisterField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    onChanged: (_) => _validatePasswordMatch(),
                  ),
                ),
                const SizedBox(height: 14),
                _staggered(
                  index++,
                  child: _AuroraRegisterField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    onChanged: (_) => _validatePasswordMatch(),
                  ),
                ),
                const SizedBox(height: 24),
                _staggered(index++, child: _buildCreateButton()),
                if (widget.onLoginTap != null) ...[
                  const SizedBox(height: 18),
                  _staggered(
                    index++,
                    child: Center(
                      child: GestureDetector(
                        onTap: widget.onLoginTap,
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF00E5CC),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5CC), Color(0xFF7B2FF7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5CC).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleRegister,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final delay = (index * 0.08).clamp(0.0, 0.7);
    final end = (delay + 0.3).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  void _validatePasswordMatch() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      if (confirm.isNotEmpty && password != confirm) {
        _passwordError = 'Passwords do not match';
      } else {
        _passwordError = null;
      }
    });
  }

  void _handleRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please complete all fields.');
      return;
    }
    if (!AuthValidators.isValidEmail(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (password != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    setState(() => _passwordError = null);

    context.read<AuthBloc>().add(
      RegisterWithEmailEvent(email: email, password: password),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter (same aurora concept, slightly shifted colors)
// ---------------------------------------------------------------------------
class _AuroraRegisterPainter extends CustomPainter {
  _AuroraRegisterPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.3 + 0.15 * sin(t)),
        size.height * (0.25 + 0.1 * cos(t * 0.7)),
      ),
      radius: size.width * 0.55,
      color: const Color(0xFF7B2FF7).withValues(alpha: 0.22),
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.7 + 0.1 * cos(t * 0.8)),
        size.height * (0.5 + 0.12 * sin(t * 0.6)),
      ),
      radius: size.width * 0.5,
      color: const Color(0xFF00E5CC).withValues(alpha: 0.2),
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.4 + 0.2 * sin(t * 0.5)),
        size.height * (0.75 + 0.08 * cos(t * 1.2)),
      ),
      radius: size.width * 0.5,
      color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraRegisterPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Aurora Register Field
// ---------------------------------------------------------------------------
class _AuroraRegisterField extends StatelessWidget {
  const _AuroraRegisterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color:
              errorText == null
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.redAccent.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          errorText: errorText,
          errorStyle: const TextStyle(color: Colors.redAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF00E5CC).withValues(alpha: 0.8),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
