// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/presentation/widgets/phone_auth_dialog.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

/// Wave-themed login page with animated liquid wave header
/// and clean Material 3 form on a light surface.
class WaveLoginPage extends StatefulWidget {
  const WaveLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<WaveLoginPage> createState() => _WaveLoginPageState();
}

class _WaveLoginPageState extends State<WaveLoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _entranceController;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final RememberMeService _rememberMeService = RememberMeService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _didPushVerificationPage = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberMe();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  Future<void> _loadRememberMe() async {
    final value = await _rememberMeService.load();
    if (mounted) setState(() => _rememberMe = value);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? const Color(0xFF121212) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final waveColor1 =
        isDark ? const Color(0xFF1A237E) : const Color(0xFF1A237E);
    final waveColor2 =
        isDark ? const Color(0xFF00838F) : const Color(0xFF00BCD4);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleStateChange,
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: surfaceColor,
          body: Stack(
            children: [
              // Wave header
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.38,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder:
                      (context, _) => CustomPaint(
                        painter: _WavePainter(
                          progress: _waveController.value,
                          color1: waveColor1,
                          color2: waveColor2,
                        ),
                        size: Size.infinite,
                      ),
                ),
              ),

              // Title on wave
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40, left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.config.logo != null) ...[
                        widget.config.logo!,
                        const SizedBox(height: 12),
                      ],
                      Text(
                        widget.config.loginTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.config.loginSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form area
              Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.32,
                    left: 24,
                    right: 24,
                    bottom: 32,
                  ),
                  child: _buildForm(
                    context,
                    errorMessage: errorMessage,
                    onSurfaceColor: onSurfaceColor,
                    waveColor1: waveColor1,
                  ),
                ),
              ),

              // Loading overlay
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
    BuildContext context, {
    String? errorMessage,
    required Color onSurfaceColor,
    required Color waveColor1,
  }) {
    var index = 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          _staggered(
            index++,
            child: _WaveTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              accentColor: waveColor1,
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          _staggered(
            index++,
            child: _WaveTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              accentColor: waveColor1,
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
            ),
          ),

          // Remember me + Forgot password
          const SizedBox(height: 8),
          _staggered(
            index++,
            child: Row(
              children: [
                if (widget.config.showRememberMe)
                  InkWell(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged:
                                (_) =>
                                    setState(() => _rememberMe = !_rememberMe),
                            activeColor: waveColor1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: onSurfaceColor.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (widget.config.showForgotPassword &&
                    widget.onForgotPasswordTap != null)
                  TextButton(
                    onPressed: widget.onForgotPasswordTap,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: waveColor1,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Sign In Button
          const SizedBox(height: 20),
          _staggered(
            index++,
            child: _WaveButton(
              label: 'Sign In',
              icon: Icons.arrow_forward_rounded,
              color: waveColor1,
              onPressed: _handleSignIn,
            ),
          ),

          // Google
          if (widget.config.showGoogleSignIn) ...[
            const SizedBox(height: 12),
            _staggered(
              index++,
              child: _WavePillButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                borderColor: onSurfaceColor.withValues(alpha: 0.15),
                textColor: onSurfaceColor,
                onPressed: _handleGoogleSignIn,
              ),
            ),
          ],

          // Divider
          if (widget.config.showPhoneSignIn ||
              widget.config.showAnonymousSignIn) ...[
            const SizedBox(height: 20),
            _staggered(
              index++,
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: onSurfaceColor.withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        color: onSurfaceColor.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: onSurfaceColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _staggered(
              index++,
              child: Row(
                children: [
                  if (widget.config.showPhoneSignIn)
                    Expanded(
                      child: _WavePillButton(
                        label: 'Phone',
                        icon: Icons.phone_android,
                        borderColor: onSurfaceColor.withValues(alpha: 0.15),
                        textColor: onSurfaceColor,
                        onPressed: _handlePhoneSignIn,
                      ),
                    ),
                  if (widget.config.showPhoneSignIn &&
                      widget.config.showAnonymousSignIn)
                    const SizedBox(width: 12),
                  if (widget.config.showAnonymousSignIn)
                    Expanded(
                      child: _WavePillButton(
                        label: 'Guest',
                        icon: Icons.person_outline,
                        borderColor: onSurfaceColor.withValues(alpha: 0.15),
                        textColor: onSurfaceColor,
                        onPressed: _handleAnonymousSignIn,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Register
          if (widget.config.showRegister && widget.onRegisterTap != null) ...[
            const SizedBox(height: 24),
            _staggered(
              index++,
              child: Center(
                child: GestureDetector(
                  onTap: widget.onRegisterTap,
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: onSurfaceColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: waveColor1,
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

  // --- Handlers ---

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
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (!AuthValidators.isValidEmail(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
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

  Future<void> _handleAnonymousSignIn() async {
    await _rememberMeService.save(value: _rememberMe);
    if (!mounted) return;
    context.read<AuthBloc>().add(const SignInAnonymouslyEvent());
  }

  void _handlePhoneSignIn() {
    showDialog<void>(
      context: context,
      builder:
          (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const PhoneAuthDialog(),
          ),
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
// Wave Custom Painter — animated sine-wave header
// ---------------------------------------------------------------------------
class _WavePainter extends CustomPainter {
  _WavePainter({
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

    // Background gradient
    final bgPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Wave 1 (front)
    _drawWave(canvas, size, t, 0.85, color2.withValues(alpha: 0.4), 30, 0);
    // Wave 2 (back)
    _drawWave(
      canvas,
      size,
      t + pi,
      0.9,
      color1.withValues(alpha: 0.3),
      20,
      pi / 3,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double t,
    double baseY,
    Color color,
    double amplitude,
    double phaseOffset,
  ) {
    final path = Path();
    path.moveTo(0, size.height);

    for (var x = 0.0; x <= size.width; x += 1) {
      final y =
          size.height * baseY +
          amplitude * sin((x / size.width * 2 * pi) + t + phaseOffset) +
          amplitude * 0.5 * sin((x / size.width * 4 * pi) + t * 0.7);
      if (x == 0) {
        path.lineTo(0, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Wave Text Field — Material 3 outlined style
// ---------------------------------------------------------------------------
class _WaveTextField extends StatelessWidget {
  const _WaveTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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

// ---------------------------------------------------------------------------
// Wave CTA Button
// ---------------------------------------------------------------------------
class _WaveButton extends StatelessWidget {
  const _WaveButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wave Pill Button (outlined, for social/alt sign-in)
// ---------------------------------------------------------------------------
class _WavePillButton extends StatelessWidget {
  const _WavePillButton({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
