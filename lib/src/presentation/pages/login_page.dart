import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/core/utils/auth_validators.dart';
import 'package:remote_auth_module/src/presentation/pages/email_verification_page.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_gradient_scaffold.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_input_field.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';
import 'package:remote_auth_module/src/presentation/widgets/phone_auth_dialog.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onRegisterTap,
    this.onForgotPasswordTap,
    this.onAuthenticated,
    this.onVerificationRequired,
    this.logo,
    this.title = 'Welcome Back',
    this.showGoogleSignIn = true,
    this.showPhoneSignIn = true,
    this.showAnonymousSignIn = true,
  });
  final VoidCallback? onRegisterTap;
  final VoidCallback? onForgotPasswordTap;
  final void Function(AuthUser user)? onAuthenticated;
  final void Function(AuthUser user)? onVerificationRequired;
  final Widget? logo;
  final String title;
  final bool showGoogleSignIn;
  final bool showPhoneSignIn;
  final bool showAnonymousSignIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
  }

  Future<void> _loadRememberMe() async {
    final value = await _rememberMeService.load();
    if (mounted) {
      setState(() => _rememberMe = value);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          widget.onAuthenticated?.call(state.user);
          return;
        }

        if (state is EmailVerificationRequiredState) {
          widget.onVerificationRequired?.call(state.user);
          if (widget.onVerificationRequired == null &&
              !_didPushVerificationPage) {
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
      },

      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;

        return AuthGradientScaffold(
          isLoading: state is AuthLoadingState,
          child: AuthGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child:
                      widget.logo ??
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.onPrimary.withValues(alpha: 0.18),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: colorScheme.onPrimary,
                          size: 36,
                        ),
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.72),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthStatusBanner(message: errorMessage),
                ],
                const SizedBox(height: 26),
                AuthInputField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  onToggleObscure:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged:
                                (_) =>
                                    setState(() => _rememberMe = !_rememberMe),
                            activeColor: colorScheme.onPrimary,
                            checkColor: colorScheme.primary,
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.84,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.onForgotPasswordTap != null)
                      TextButton(
                        onPressed: widget.onForgotPasswordTap,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AuthActionButton(
                  label: 'Sign In',
                  onPressed: _handleSignIn,
                  icon: Icons.login,
                ),
                if (widget.showGoogleSignIn) ...[
                  const SizedBox(height: 14),
                  AuthActionButton(
                    label: 'Continue with Google',
                    style: AuthActionButtonStyle.subtle,
                    onPressed: _handleGoogleSignIn,
                    icon: Icons.g_mobiledata,
                  ),
                ],
                if (widget.showPhoneSignIn || widget.showAnonymousSignIn) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (widget.showPhoneSignIn)
                        Expanded(
                          child: AuthActionButton(
                            label: 'Phone',
                            style: AuthActionButtonStyle.subtle,
                            onPressed: _handlePhoneSignIn,
                            icon: Icons.phone_android,
                          ),
                        ),
                      if (widget.showPhoneSignIn && widget.showAnonymousSignIn)
                        const SizedBox(width: 12),
                      if (widget.showAnonymousSignIn)
                        Expanded(
                          child: AuthActionButton(
                            label: 'Guest',
                            style: AuthActionButtonStyle.subtle,
                            onPressed: _handleAnonymousSignIn,
                            icon: Icons.person_outline,
                          ),
                        ),
                    ],
                  ),
                ],
                if (widget.onRegisterTap != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onRegisterTap,
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
    if (!mounted) {
      return;
    }

    context.read<AuthBloc>().add(
      SignInWithEmailEvent(email: email, password: password),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await _rememberMeService.save(value: _rememberMe);
    if (!mounted) {
      return;
    }

    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
  }

  Future<void> _handleAnonymousSignIn() async {
    await _rememberMeService.save(value: _rememberMe);
    if (!mounted) {
      return;
    }

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
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
