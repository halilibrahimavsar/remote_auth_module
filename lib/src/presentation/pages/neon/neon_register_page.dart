// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Neon-themed registration page.
class NeonRegisterPage extends StatefulWidget {
  const NeonRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<NeonRegisterPage> createState() => _NeonRegisterPageState();
}

class _NeonRegisterPageState extends State<NeonRegisterPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;
  late final AnimationController _particleController;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  String? _passwordError;

  static const _neonBlue = Color(0xFF00D4FF);
  static const _neonPink = Color(0xFFFF006E);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _particleController.dispose();
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
              backgroundColor: _neonPink,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Grid
              CustomPaint(painter: _GridPainter(), size: Size.infinite),
              // Particles
              AnimatedBuilder(
                animation: _particleController,
                builder:
                    (context, _) => CustomPaint(
                      painter: _NeonParticlePainter(
                        progress: _particleController.value,
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
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: _neonBlue.withValues(alpha: 0.8),
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
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_neonBlue),
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
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final blur = 10.0 + _pulseController.value * 6;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _neonPink.withValues(alpha: 0.4),
                width: 1.5,
              ),
              color: const Color(0xFF0A0A0A),
              boxShadow: [
                BoxShadow(
                  color: _neonPink.withValues(alpha: 0.12),
                  blurRadius: blur,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Padding(
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
                    color: _neonPink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: _neonPink, blurRadius: 8)],
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _neonPink.withValues(alpha: 0.4)),
                    color: _neonPink.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: _neonPink.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _staggered(
                index++,
                child: _NeonRegField(
                  controller: _emailController,
                  label: 'EMAIL',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 14),
              _staggered(
                index++,
                child: _NeonRegField(
                  controller: _passwordController,
                  label: 'PASSWORD',
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
                      color: _neonBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  onChanged: (_) => _validatePasswordMatch(),
                ),
              ),
              const SizedBox(height: 14),
              _staggered(
                index++,
                child: _NeonRegField(
                  controller: _confirmPasswordController,
                  label: 'CONFIRM PASSWORD',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
                  onChanged: (_) => _validatePasswordMatch(),
                ),
              ),
              const SizedBox(height: 24),
              _staggered(
                index++,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glow = 8.0 + _pulseController.value * 5;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _neonPink,
                        boxShadow: [
                          BoxShadow(
                            color: _neonPink.withValues(alpha: 0.4),
                            blurRadius: glow,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleRegister,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add_alt_1,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onLoginTap != null) ...[
                const SizedBox(height: 20),
                _staggered(
                  index++,
                  child: Center(
                    child: GestureDetector(
                      onTap: widget.onLoginTap,
                      child: RichText(
                        text: TextSpan(
                          text: 'HAVE ACCOUNT? ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          children: const [
                            TextSpan(
                              text: 'SIGN IN',
                              style: TextStyle(
                                color: _neonBlue,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: _neonBlue, blurRadius: 6),
                                ],
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
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final delay = (index * 0.07).clamp(0.0, 0.6);
    final end = (delay + 0.3).clamp(0.0, 1.0);
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

  void _validatePasswordMatch() {
    final confirm = _confirmPasswordController.text;
    final password = _passwordController.text;
    setState(() {
      _passwordError =
          confirm.isNotEmpty && password != confirm
              ? 'Passwords do not match'
              : null;
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
        backgroundColor: _neonPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid background painter (shared concept)
// ---------------------------------------------------------------------------
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.03)
          ..strokeWidth = 1;
    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Floating neon particles
// ---------------------------------------------------------------------------
class _NeonParticlePainter extends CustomPainter {
  _NeonParticlePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    for (var i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;

      final x = baseX + sin(progress * 2 * pi * speed + phase) * 25;
      final y = (baseY - progress * size.height * 0.25 * speed) % size.height;

      final color =
          i.isEven
              ? const Color(
                0xFFFF006E,
              ).withValues(alpha: 0.12 + rng.nextDouble() * 0.1)
              : const Color(
                0xFF00D4FF,
              ).withValues(alpha: 0.1 + rng.nextDouble() * 0.08);

      canvas.drawCircle(
        Offset(x, y),
        1.5 + rng.nextDouble() * 1.5,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_NeonParticlePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Neon Register Field
// ---------------------------------------------------------------------------
class _NeonRegField extends StatefulWidget {
  const _NeonRegField({
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
  State<_NeonRegField> createState() => _NeonRegFieldState();
}

class _NeonRegFieldState extends State<_NeonRegField> {
  bool _focused = false;

  static const _neonBlue = Color(0xFF00D4FF);
  static const _neonPink = Color(0xFFFF006E);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF0D0D0D),
        border: Border.all(
          color:
              widget.errorText != null
                  ? _neonPink
                  : _focused
                  ? _neonBlue
                  : _neonBlue.withValues(alpha: 0.2),
          width: _focused || widget.errorText != null ? 1.5 : 1,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: _neonBlue.withValues(alpha: 0.12),
                    blurRadius: 10,
                  ),
                ]
                : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: const TextStyle(color: Colors.white, letterSpacing: 0.3),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _neonBlue.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(color: _neonPink, fontSize: 11),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _neonBlue.withValues(alpha: 0.6),
              size: 20,
            ),
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}
