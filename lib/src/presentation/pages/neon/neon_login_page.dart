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

/// Neon-themed login page — cyberpunk, bold, dark with glowing neon accents.
class NeonLoginPage extends StatefulWidget {
  const NeonLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<NeonLoginPage> createState() => _NeonLoginPageState();
}

class _NeonLoginPageState extends State<NeonLoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _entranceController;
  late final AnimationController _typewriterController;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final RememberMeService _rememberMeService = RememberMeService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _didPushVerificationPage = false;

  // Typewriter state
  String _displayedTitle = '';
  int _charIndex = 0;

  static const _neonBlue = Color(0xFF00D4FF);
  static const _neonPink = Color(0xFFFF006E);
  static const _bgColor = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberMe();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Typewriter
    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.config.loginTitle.length * 80),
    );
    _typewriterController.addListener(_onTypewriterTick);
    // Start after a short delay
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _typewriterController.forward();
    });
  }

  void _onTypewriterTick() {
    final title = widget.config.loginTitle;
    final newIndex = (_typewriterController.value * title.length).floor().clamp(
      0,
      title.length,
    );
    if (newIndex != _charIndex) {
      _charIndex = newIndex;
      if (mounted) {
        setState(() => _displayedTitle = title.substring(0, _charIndex));
      }
    }
  }

  Future<void> _loadRememberMe() async {
    final value = await _rememberMeService.load();
    if (mounted) setState(() => _rememberMe = value);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _entranceController.dispose();
    _typewriterController.removeListener(_onTypewriterTick);
    _typewriterController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
          backgroundColor: _bgColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Grid lines background
              CustomPaint(painter: _GridPainter(), size: Size.infinite),

              // Floating neon particles
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

              // Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: _buildCard(errorMessage),
                  ),
                ),
              ),

              // Loading overlay
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final blurRadius = 12.0 + (_pulseController.value * 8);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _neonBlue.withValues(alpha: 0.5),
                width: 1.5,
              ),
              color: const Color(0xFF0A0A0A),
              boxShadow: [
                BoxShadow(
                  color: _neonBlue.withValues(alpha: 0.15),
                  blurRadius: blurRadius,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: _neonPink.withValues(alpha: 0.08),
                  blurRadius: blurRadius * 1.5,
                  spreadRadius: 2,
                  offset: const Offset(8, 8),
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
            children: _buildFormFields(errorMessage),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(String? errorMessage) {
    final items = <Widget>[];
    var index = 0;

    // Logo
    items.add(
      _staggered(
        index++,
        child: Center(
          child:
              widget.config.logo ??
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _neonBlue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _neonBlue.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: _neonBlue,
                  size: 30,
                ),
              ),
        ),
      ),
    );

    // Typewriter title
    items.add(const SizedBox(height: 20));
    items.add(
      _staggered(
        index++,
        child: Center(
          child: Text(
            _displayedTitle +
                (_charIndex < widget.config.loginTitle.length ? '▌' : ''),
            style: const TextStyle(
              color: _neonBlue,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              shadows: [Shadow(color: _neonBlue, blurRadius: 10)],
            ),
          ),
        ),
      ),
    );

    // Subtitle
    items.add(const SizedBox(height: 6));
    items.add(
      _staggered(
        index++,
        child: Text(
          widget.config.loginSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );

    // Error
    if (errorMessage != null) {
      items.add(const SizedBox(height: 16));
      items.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _neonPink.withValues(alpha: 0.4)),
            color: _neonPink.withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: _neonPink, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: _neonPink.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Email
    items.add(const SizedBox(height: 28));
    items.add(
      _staggered(
        index++,
        child: _NeonTextField(
          controller: _emailController,
          label: 'EMAIL',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );

    // Password
    items.add(const SizedBox(height: 14));
    items.add(
      _staggered(
        index++,
        child: _NeonTextField(
          controller: _passwordController,
          label: 'PASSWORD',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _neonBlue.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );

    // Remember me + Forgot password
    items.add(const SizedBox(height: 10));
    items.add(
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
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged:
                            (_) => setState(() => _rememberMe = !_rememberMe),
                        activeColor: _neonBlue,
                        checkColor: _bgColor,
                        side: BorderSide(
                          color: _neonBlue.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        letterSpacing: 0.3,
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
                child: Text(
                  'FORGOT?',
                  style: TextStyle(
                    color: _neonPink.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Sign In button
    items.add(const SizedBox(height: 20));
    items.add(
      _staggered(
        index++,
        child: _NeonButton(
          label: 'SIGN IN',
          icon: Icons.arrow_forward_rounded,
          color: _neonBlue,
          onPressed: _handleSignIn,
          pulseController: _pulseController,
        ),
      ),
    );

    // Google
    if (widget.config.showGoogleSignIn) {
      items.add(const SizedBox(height: 12));
      items.add(
        _staggered(
          index++,
          child: _NeonButton(
            label: 'GOOGLE',
            icon: Icons.g_mobiledata,
            color: Colors.white.withValues(alpha: 0.5),
            onPressed: _handleGoogleSignIn,
            isGhost: true,
          ),
        ),
      );
    }

    // Divider + Phone/Guest
    if (widget.config.showPhoneSignIn || widget.config.showAnonymousSignIn) {
      items.add(const SizedBox(height: 16));
      items.add(
        _staggered(
          index++,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: _neonBlue.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: _neonBlue.withValues(alpha: 0.3),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: _neonBlue.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      );

      items.add(const SizedBox(height: 12));
      items.add(
        _staggered(
          index++,
          child: Row(
            children: [
              if (widget.config.showPhoneSignIn)
                Expanded(
                  child: _NeonIconChip(
                    icon: Icons.phone_android,
                    label: 'PHONE',
                    color: _neonPink,
                    onTap: _handlePhoneSignIn,
                  ),
                ),
              if (widget.config.showPhoneSignIn &&
                  widget.config.showAnonymousSignIn)
                const SizedBox(width: 12),
              if (widget.config.showAnonymousSignIn)
                Expanded(
                  child: _NeonIconChip(
                    icon: Icons.person_outline,
                    label: 'GUEST',
                    color: _neonBlue,
                    onTap: _handleAnonymousSignIn,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Register
    if (widget.config.showRegister && widget.onRegisterTap != null) {
      items.add(const SizedBox(height: 20));
      items.add(
        _staggered(
          index++,
          child: Center(
            child: GestureDetector(
              onTap: widget.onRegisterTap,
              child: RichText(
                text: TextSpan(
                  text: 'NO ACCOUNT? ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'SIGN UP',
                      style: TextStyle(
                        color: _neonBlue,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: _neonBlue, blurRadius: 6)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return items;
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
        backgroundColor: _neonPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid background painter
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

  static const _neonBlue = Color(0xFF00D4FF);
  static const _neonPink = Color(0xFFFF006E);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    const count = 30;

    for (var i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;

      final x = baseX + sin(progress * 2 * pi * speed + phase) * 30;
      final y = (baseY - progress * size.height * 0.3 * speed) % size.height;

      final alpha = 0.15 + rng.nextDouble() * 0.15;
      final color =
          i.isEven
              ? _neonBlue.withValues(alpha: alpha)
              : _neonPink.withValues(alpha: alpha * 0.7);

      final r = 1.5 + rng.nextDouble() * 2;

      // Glow trail
      if (i < 15) {
        final trailAlpha = alpha * 0.3;
        canvas.drawCircle(
          Offset(x - 2, y + 3),
          r * 2,
          Paint()
            ..color = color.withValues(alpha: trailAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_NeonParticlePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Neon Text Field
// ---------------------------------------------------------------------------
class _NeonTextField extends StatefulWidget {
  const _NeonTextField({
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
  State<_NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<_NeonTextField> {
  bool _focused = false;

  static const _neonBlue = Color(0xFF00D4FF);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF0D0D0D),
        border: Border.all(
          color: _focused ? _neonBlue : _neonBlue.withValues(alpha: 0.2),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: _neonBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
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
          style: const TextStyle(color: Colors.white, letterSpacing: 0.3),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _neonBlue.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF006E), fontSize: 11),
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

// ---------------------------------------------------------------------------
// Neon CTA Button
// ---------------------------------------------------------------------------
class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.isGhost = false,
    this.pulseController,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isGhost;
  final AnimationController? pulseController;

  @override
  Widget build(BuildContext context) {
    if (isGhost) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon:
              icon != null
                  ? Icon(icon, size: 18, color: color)
                  : const SizedBox.shrink(),
          label: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (pulseController != null) {
      return AnimatedBuilder(
        animation: pulseController!,
        builder: (context, c) {
          final glow = 8.0 + pulseController!.value * 6;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: glow,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: c,
          );
        },
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Neon Icon Chip (Phone / Guest)
// ---------------------------------------------------------------------------
class _NeonIconChip extends StatelessWidget {
  const _NeonIconChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            color: color.withValues(alpha: 0.04),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
