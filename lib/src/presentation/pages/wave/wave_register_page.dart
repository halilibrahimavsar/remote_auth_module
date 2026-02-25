// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Wave-themed registration page.
class WaveRegisterPage extends StatefulWidget {
  const WaveRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<WaveRegisterPage> createState() => _WaveRegisterPageState();
}

class _WaveRegisterPageState extends State<WaveRegisterPage>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
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

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF121212) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final waveColor1 = const Color(0xFF1A237E);
    final waveColor2 =
        isDark ? const Color(0xFF00838F) : const Color(0xFF00BCD4);

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
          backgroundColor: surfaceColor,
          body: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.32,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder:
                      (context, _) => CustomPaint(
                        painter: _WaveRegisterPainter(
                          progress: _waveController.value,
                          color1: waveColor1,
                          color2: waveColor2,
                        ),
                        size: Size.infinite,
                      ),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 40, left: 28),
                      child: Text(
                        widget.config.registerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.28,
                    left: 24,
                    right: 24,
                    bottom: 32,
                  ),
                  child: _buildForm(errorMessage, onSurfaceColor, waveColor1),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(waveColor1),
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

  Widget _buildForm(
    String? errorMessage,
    Color onSurfaceColor,
    Color accentColor,
  ) {
    var index = 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null) ...[
            _staggered(
              index++,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _staggered(
            index++,
            child: _WaveRegisterField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          _staggered(
            index++,
            child: _WaveRegisterField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              accentColor: accentColor,
              suffixIcon: IconButton(
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: onSurfaceColor.withValues(alpha: 0.4),
                ),
              ),
              onChanged: (_) => _validatePasswordMatch(),
            ),
          ),
          const SizedBox(height: 16),
          _staggered(
            index++,
            child: _WaveRegisterField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              accentColor: accentColor,
              errorText: _passwordError,
              onChanged: (_) => _validatePasswordMatch(),
            ),
          ),
          const SizedBox(height: 24),
          _staggered(
            index++,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: onSurfaceColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: accentColor,
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
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final delay = (index * 0.08).clamp(0.0, 0.6);
    final end = (delay + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wave Register Painter
// ---------------------------------------------------------------------------
class _WaveRegisterPainter extends CustomPainter {
  _WaveRegisterPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });
  final double progress;
  final Color color1;
  final Color color2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;
    final bgPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawWave(canvas, size, t, 0.82, color2.withValues(alpha: 0.4), 25);
    _drawWave(canvas, size, t + pi, 0.88, color1.withValues(alpha: 0.3), 18);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double t,
    double baseY,
    Color color,
    double amplitude,
  ) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y =
          size.height * baseY +
          amplitude * sin((x / size.width * 2 * pi) + t) +
          amplitude * 0.5 * sin((x / size.width * 4 * pi) + t * 0.7);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WaveRegisterPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Wave Register Field
// ---------------------------------------------------------------------------
class _WaveRegisterField extends StatelessWidget {
  const _WaveRegisterField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, color: accentColor.withValues(alpha: 0.7)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
