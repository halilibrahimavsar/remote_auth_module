// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/templates/auth_template_config.dart';

/// Premium Zen-themed register page.
class ZenRegisterPage extends StatefulWidget {
  const ZenRegisterPage({
    super.key,
    this.config = const AuthTemplateConfig(),
    this.onLoginTap,
  });

  final AuthTemplateConfig config;
  final VoidCallback? onLoginTap;

  @override
  State<ZenRegisterPage> createState() => _ZenRegisterPageState();
}

class _ZenRegisterPageState extends State<ZenRegisterPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _bgController;
  late final AnimationController _contentController;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBF8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF6B705C),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              _ZenBreathingBackgroundInternal(controller: _bgController),
              _ZenPetalsBackgroundInternal(controller: _bgController),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      child: const Column(
        children: [
          Text(
            'Begin Journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF333533),
              fontSize: 30,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a space for your thoughts',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B705C),
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(String? errorMessage, bool isLoading) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.6),
      ),
      child: Column(
        children: [
          if (errorMessage != null) ...[
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
          _ZenInputInternal(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _ZenInputInternal(
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
          const SizedBox(height: 20),
          _ZenInputInternal(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              onPressed:
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF6B705C).withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _ZenActionBtn(
            label: 'Create Account',
            onPressed: _handleRegister,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0),
      ),
      child: Center(
        child: GestureDetector(
          onTap: widget.onLoginTap ?? () => Navigator.of(context).pop(),
          child: RichText(
            text: const TextSpan(
              text: "Already a member? ",
              style: TextStyle(color: Color(0xFF6B705C), fontSize: 14),
              children: [
                TextSpan(
                  text: 'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final error = AuthValidators.validatePassword(password);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.read<AuthBloc>().add(
      RegisterWithEmailEvent(email: email, password: password),
    );
  }
}

class _ZenInputInternal extends StatelessWidget {
  const _ZenInputInternal({
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

class _ZenActionBtn extends StatelessWidget {
  const _ZenActionBtn({
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
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _ZenBreathingBackgroundInternal extends StatelessWidget {
  const _ZenBreathingBackgroundInternal({required this.controller});
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
              center: const Alignment(0.4, -0.4),
              radius: 1.5 + (sinVal * 0.4),
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

class _ZenPetalsBackgroundInternal extends StatelessWidget {
  const _ZenPetalsBackgroundInternal({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PetalsPainterInternal(progress: controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _PetalsPainterInternal extends CustomPainter {
  _PetalsPainterInternal({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF6B705C).withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;

    for (var i = 0; i < 6; i++) {
      final t = (progress + (i / 6)) % 1.0;
      final x = size.width * (0.2 + 0.6 * math.sin(i * 2.0 + t * 0.4));
      final y = size.height * (1.1 - (t * 1.3));
      final rotation = t * math.pi * 3;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final path =
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(8, -12, 0, -24)
            ..quadraticBezierTo(-8, -12, 0, 0);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalsPainterInternal oldDelegate) => true;
}
