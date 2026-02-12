import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../bloc/auth_bloc.dart';

/// A pre-built, theme-aware login page.
///
/// Uses the host app's [ThemeData] for all styling.
/// Navigation is controlled via callbacks.
///
/// ```dart
/// LoginPage(
///   onRegisterTap: () => Navigator.push(...),
///   onForgotPasswordTap: () => Navigator.push(...),
///   onAuthenticated: (user) => Navigator.pushReplacement(...),
/// )
/// ```
class LoginPage extends StatefulWidget {
  /// Called when the user taps "Create Account".
  final VoidCallback? onRegisterTap;

  /// Called when the user taps "Forgot Password?".
  final VoidCallback? onForgotPasswordTap;

  /// Called when authentication succeeds.
  final void Function(AuthenticatedState state)? onAuthenticated;

  /// Optional custom logo widget.
  final Widget? logo;

  /// Optional title text. Defaults to "Welcome Back".
  final String title;

  /// Whether to show the Google sign-in button.
  final bool showGoogleSignIn;

  const LoginPage({
    super.key,
    this.onRegisterTap,
    this.onForgotPasswordTap,
    this.onAuthenticated,
    this.logo,
    this.title = 'Welcome Back',
    this.showGoogleSignIn = true,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
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
    _animationController.dispose();
    super.dispose();
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
        } else if (state is PasswordResetSentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset email sent.'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthenticatedState) {
          widget.onAuthenticated?.call(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Gradient background using theme colors
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Center(
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
                                color: colorScheme.surface.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Logo
                                  if (widget.logo != null) ...[
                                    widget.logo!,
                                    const SizedBox(height: 20),
                                  ],

                                  // Title
                                  Text(
                                    widget.title,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
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

                                  // Email field
                                  _buildTextField(
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  _buildTextField(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    controller: _passwordController,
                                    obscure: _obscurePassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // Forgot password
                                  if (widget.onForgotPasswordTap != null)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: widget.onForgotPasswordTap,
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 20),

                                  // Sign in button
                                  _buildPrimaryButton(
                                    label: 'Sign In',
                                    onTap: _handleSignIn,
                                  ),

                                  // Google sign in
                                  if (widget.showGoogleSignIn) ...[
                                    const SizedBox(height: 20),
                                    _buildDivider(),
                                    const SizedBox(height: 20),
                                    _buildOutlinedButton(
                                      label: 'Continue with Google',
                                      icon: Icons.g_mobiledata,
                                      onTap: () {
                                        context
                                            .read<AuthBloc>()
                                            .add(const SignInWithGoogleEvent());
                                      },
                                    ),
                                  ],

                                  // Register link
                                  if (widget.onRegisterTap != null) ...[
                                    const SizedBox(height: 20),
                                    TextButton(
                                      onPressed: widget.onRegisterTap,
                                      child: Text(
                                        "Don't have an account? Sign Up",
                                        style: TextStyle(
                                          color: colorScheme.onPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Loading overlay
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

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthBloc>().add(
          SignInWithEmailEvent(email: email, password: password),
        );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.onPrimary.withValues(alpha: 0.15),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(color: colorScheme.onPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: colorScheme.onPrimary),
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
    required IconData icon,
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
          border: Border.all(
            color: colorScheme.onPrimary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.onPrimary, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final color =
        Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3);
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Divider(color: color)),
      ],
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
