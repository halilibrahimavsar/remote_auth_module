// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';
import 'package:remote_auth_module/src/presentation/widgets/phone_auth_dialog.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

/// Aurora-themed login page with animated mesh gradient and staggered
/// form entrance animations. Dark, ethereal, futuristic.
class AuroraLoginPage extends StatefulWidget {
  const AuroraLoginPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<AuroraLoginPage> createState() => _AuroraLoginPageState();
}

class _AuroraLoginPageState extends State<AuroraLoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _auroraController;
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;

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

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
    _auroraController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
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
          backgroundColor: const Color(0xFF0B0E1A),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Animated aurora background
              AnimatedBuilder(
                animation: _auroraController,
                builder:
                    (context, _) => CustomPaint(
                      painter: _AuroraPainter(
                        progress: _auroraController.value,
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
                    child: _buildCard(
                      context,
                      errorMessage: errorMessage,
                      isLoading: isLoading,
                    ),
                  ),
                ),
              ),

              // Loading overlay
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

  Widget _buildCard(
    BuildContext context, {
    String? errorMessage,
    required bool isLoading,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowOpacity = 0.15 + (_pulseController.value * 0.1);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5CC).withValues(alpha: glowOpacity),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(
                    0xFF7B2FF7,
                  ).withValues(alpha: glowOpacity * 0.6),
                  blurRadius: 60,
                  spreadRadius: 4,
                  offset: const Offset(20, 20),
                ),
              ],
            ),
            child: child,
          );
        },
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
                children: _buildFormFields(errorMessage),
              ),
            ),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5CC), Color(0xFF7B2FF7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5CC).withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 34,
                ),
              ),
        ),
      ),
    );

    // Title
    items.add(const SizedBox(height: 20));
    items.add(
      _staggered(
        index++,
        child: Text(
          widget.config.loginTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
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
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ),
    );

    // Error
    if (errorMessage != null) {
      items.add(const SizedBox(height: 16));
      items.add(AuthStatusBanner(message: errorMessage));
    }

    // Email
    items.add(const SizedBox(height: 28));
    items.add(
      _staggered(
        index++,
        child: _AuroraTextField(
          controller: _emailController,
          label: 'Email',
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
        child: _AuroraTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white.withValues(alpha: 0.6),
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
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged:
                            (_) => setState(() => _rememberMe = !_rememberMe),
                        activeColor: const Color(0xFF00E5CC),
                        checkColor: const Color(0xFF0B0E1A),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
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
                  'Forgot password?',
                  style: TextStyle(
                    color: const Color(0xFF00E5CC).withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
        child: _AuroraButton(
          label: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          onPressed: _handleSignIn,
        ),
      ),
    );

    // Google
    if (widget.config.showGoogleSignIn) {
      items.add(const SizedBox(height: 12));
      items.add(
        _staggered(
          index++,
          child: _AuroraButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata,
            onPressed: _handleGoogleSignIn,
            isOutlined: true,
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
                child: Divider(color: Colors.white.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.15)),
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
                  child: _AuroraIconButton(
                    icon: Icons.phone_android,
                    label: 'Phone',
                    onTap: _handlePhoneSignIn,
                  ),
                ),
              if (widget.config.showPhoneSignIn &&
                  widget.config.showAnonymousSignIn)
                const SizedBox(width: 12),
              if (widget.config.showAnonymousSignIn)
                Expanded(
                  child: _AuroraIconButton(
                    icon: Icons.person_outline,
                    label: 'Guest',
                    onTap: _handleAnonymousSignIn,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Register link
    if (widget.config.showRegister && widget.onRegisterTap != null) {
      items.add(const SizedBox(height: 18));
      items.add(
        _staggered(
          index++,
          child: Center(
            child: GestureDetector(
              onTap: widget.onRegisterTap,
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
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
      );
    }

    return items;
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
// Aurora Custom Painter — animated flowing mesh gradient
// ---------------------------------------------------------------------------
class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * pi;

    // 4 large soft gradient blobs that drift
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.3 + 0.15 * sin(t)),
        size.height * (0.2 + 0.1 * cos(t * 0.7)),
      ),
      radius: size.width * 0.6,
      colors: [
        const Color(0xFF00E5CC).withValues(alpha: 0.25),
        const Color(0xFF00E5CC).withValues(alpha: 0.0),
      ],
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.7 + 0.1 * cos(t * 0.8)),
        size.height * (0.35 + 0.12 * sin(t * 0.6)),
      ),
      radius: size.width * 0.5,
      colors: [
        const Color(0xFF7B2FF7).withValues(alpha: 0.22),
        const Color(0xFF7B2FF7).withValues(alpha: 0.0),
      ],
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.5 + 0.2 * sin(t * 0.5)),
        size.height * (0.65 + 0.08 * cos(t * 1.2)),
      ),
      radius: size.width * 0.55,
      colors: [
        const Color(0xFF00B4D8).withValues(alpha: 0.18),
        const Color(0xFF00B4D8).withValues(alpha: 0.0),
      ],
    );

    // 4th blob — warm pink for richer palette
    _drawBlob(
      canvas,
      size,
      center: Offset(
        size.width * (0.25 + 0.18 * cos(t * 0.9)),
        size.height * (0.8 + 0.06 * sin(t * 1.1)),
      ),
      radius: size.width * 0.45,
      colors: [
        const Color(0xFFFF6B9D).withValues(alpha: 0.14),
        const Color(0xFFFF6B9D).withValues(alpha: 0.0),
      ],
    );

    // Floating light orbs
    _drawOrbs(canvas, size, t);
  }

  void _drawOrbs(Canvas canvas, Size size, double t) {
    final rng = Random(42);
    const orbCount = 12;
    for (var i = 0; i < orbCount; i++) {
      final seed = rng.nextDouble();
      final speed = 0.3 + seed * 0.7;
      final orbRadius = 2.0 + seed * 4.0;
      final cx =
          size.width * ((rng.nextDouble() + 0.08 * sin(t * speed + i)) % 1.0);
      final cy =
          size.height *
          ((rng.nextDouble() + 0.06 * cos(t * speed * 0.8 + i * 0.5)) % 1.0);
      final alpha = 0.15 + 0.2 * sin(t * 1.5 + i * 0.8).abs();
      final paint =
          Paint()
            ..color = (i.isEven
                    ? const Color(0xFF00E5CC)
                    : const Color(0xFF7B2FF7))
                .withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), orbRadius, paint);
    }
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required List<Color> colors,
  }) {
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: colors,
          ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Aurora Text Field
// ---------------------------------------------------------------------------
class _AuroraTextField extends StatefulWidget {
  const _AuroraTextField({
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
  State<_AuroraTextField> createState() => _AuroraTextFieldState();
}

class _AuroraTextFieldState extends State<_AuroraTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusGlow;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusGlow.forward();
      } else {
        _focusGlow.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusGlow.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusGlow,
      builder: (context, child) {
        final glow = _focusGlow.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06 + glow * 0.04),
            border: Border.all(
              color:
                  Color.lerp(
                    Colors.white.withValues(alpha: 0.12),
                    const Color(0xFF00E5CC).withValues(alpha: 0.6),
                    glow,
                  )!,
              width: 1.0 + glow * 0.5,
            ),
            boxShadow:
                glow > 0.01
                    ? [
                      BoxShadow(
                        color: const Color(
                          0xFF00E5CC,
                        ).withValues(alpha: 0.15 * glow),
                        blurRadius: 12 * glow,
                        spreadRadius: 1 * glow,
                      ),
                    ]
                    : null,
          ),
          child: child,
        );
      },
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: const Color(0xFF00E5CC).withValues(alpha: 0.8),
          ),
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Aurora Gradient Button
// ---------------------------------------------------------------------------
class _AuroraButton extends StatefulWidget {
  const _AuroraButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;

  @override
  State<_AuroraButton> createState() => _AuroraButtonState();
}

class _AuroraButtonState extends State<_AuroraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onPressed,
          icon:
              widget.icon != null
                  ? Icon(widget.icon, size: 18)
                  : const SizedBox.shrink(),
          label: Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: const [
                Color(0xFF00E5CC),
                Color(0xFF7B2FF7),
                Color(0xFF00E5CC),
              ],
              stops: [0.0, _shimmerController.value, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5CC).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
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
}

// ---------------------------------------------------------------------------
// Aurora Icon Button (Phone / Guest)
// ---------------------------------------------------------------------------
class _AuroraIconButton extends StatelessWidget {
  const _AuroraIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00E5CC), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
