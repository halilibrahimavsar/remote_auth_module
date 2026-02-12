import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../bloc/auth_bloc.dart';

/// A pre-built, theme-aware registration page.
///
/// Uses the host app's [ThemeData] for all styling.
/// Navigation is controlled via callbacks.
///
/// ```dart
/// RegisterPage(
///   onLoginTap: () => Navigator.pop(context),
///   onRegistered: (user) => Navigator.pushReplacement(...),
/// )
/// ```
class RegisterPage extends StatefulWidget {
  /// Called when the user taps "Already have an account? Login".
  final VoidCallback? onLoginTap;

  /// Called after successful registration.
  final void Function(AuthenticatedState state)? onRegistered;

  /// Optional title text. Defaults to "Create Account".
  final String title;

  const RegisterPage({
    super.key,
    this.onLoginTap,
    this.onRegistered,
    this.title = 'Create Account',
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _isVerificationView = false;
  String? _errorText;
  Timer? _timer;
  int _timerDuration = 30;
  bool _isTimerRunning = false;
  bool _hasSentInitialVerification = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerDuration = 30;
      _isTimerRunning = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerDuration > 0) {
        setState(() => _timerDuration--);
      } else {
        setState(() => _isTimerRunning = false);
        timer.cancel();
      }
    });
  }

  void _validatePasswordMatch(String value, TextEditingController other) {
    setState(() {
      if (other.text.isNotEmpty && value != other.text) {
        _errorText = 'Passwords do not match';
      } else {
        _errorText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is EmailVerificationSentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent.'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is EmailVerificationRequiredState) {
          if (!_isVerificationView) {
            setState(() => _isVerificationView = true);
          }

          if (!_hasSentInitialVerification) {
            _hasSentInitialVerification = true;
            _startTimer();
            context.read<AuthBloc>().add(const SendEmailVerificationEvent());
          }
        } else if (state is AuthenticatedState) {
          widget.onRegistered?.call(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon:
                  Icon(Icons.arrow_back_ios_new, color: colorScheme.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _isVerificationView
                                  ? _buildVerificationView(state)
                                  : _buildRegisterForm(state),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state is AuthLoadingState)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: colorScheme.onPrimary,
                        size: 60,
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

  Widget _buildRegisterForm(AuthState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (state is AuthErrorState) ...[
          const SizedBox(height: 16),
          _buildStatusBanner(
            message: state.message,
            isError: true,
          ),
        ],
        const SizedBox(height: 30),
        _buildTextField(
          label: 'Email',
          icon: Icons.email_outlined,
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Password',
          icon: Icons.lock_outline,
          controller: _passwordController,
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (v) =>
              _validatePasswordMatch(v, _confirmPasswordController),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          controller: _confirmPasswordController,
          obscure: _obscurePassword,
          errorText: _errorText,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (v) => _validatePasswordMatch(v, _passwordController),
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton(
          label: 'Sign Up',
          onTap: _handleRegister,
        ),
        const SizedBox(height: 15),
        if (widget.onLoginTap != null)
          TextButton(
            onPressed: widget.onLoginTap,
            child: Text(
              'Already have an account? Login',
              style: TextStyle(
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationView(AuthState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verify your Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a verification link to\n${_emailController.text}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        if (state is AuthErrorState) ...[
          const SizedBox(height: 16),
          _buildStatusBanner(
            message: state.message,
            isError: true,
          ),
        ],
        const SizedBox(height: 30),
        _buildPrimaryButton(
          label:
              _isTimerRunning ? 'Resend in $_timerDuration s' : 'Resend Email',
          onTap: _isTimerRunning
              ? () {}
              : () {
                  context
                      .read<AuthBloc>()
                      .add(const SendEmailVerificationEvent());
                  _startTimer();
                },
        ),
        const SizedBox(height: 15),
        _buildOutlinedButton(
          label: 'I Verified It, Login',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _handleRegister() {
    if (_errorText != null) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    _hasSentInitialVerification = false;
    context.read<AuthBloc>().add(
          RegisterWithEmailEvent(email: email, password: password),
        );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.onPrimary.withValues(alpha: 0.15),
        border: Border.all(
          color: errorText != null
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.onPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: TextStyle(color: colorScheme.onPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: colorScheme.onPrimary),
          errorText: errorText,
          errorStyle: TextStyle(color: colorScheme.error),
          suffixIcon: onToggleObscure != null
              ? GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.onPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.onPrimary),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required String message,
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isError ? colorScheme.error : colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.16),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary,
            ),
      ),
    );
  }
}
