// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_gradient_scaffold.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_input_field.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.onLoginTap,
    this.onAuthenticated,
    this.onVerificationRequired,
    this.title = 'Create Account',
  });
  final VoidCallback? onLoginTap;
  final void Function(AuthUser user)? onAuthenticated;
  final void Function(AuthUser user)? onVerificationRequired;
  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  String? _passwordError;
  bool _isVerificationView = false;
  bool _isResendPending = false;
  int _timerSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          setState(() {
            _isResendPending = false;
          });
          if (!_isVerificationView) {
            setState(() => _isVerificationView = true);
          }
          // Fix: If we are in the verification view, and the page was pushed (manual or via RemoteAuthFlow),
          // we should pop ourselves so that the underlying Flow displays the EmailVerificationPage
          // without duplicates.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          widget.onVerificationRequired?.call(state.user);
          return;
        }

        if (state is EmailVerificationSentState) {
          setState(() {
            _isResendPending = false;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent.'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (state is AuthErrorState) {
          setState(() {
            _isResendPending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final errorMessage = state is AuthErrorState ? state.message : null;

        return AuthGradientScaffold(
          showBackButton: true,
          isLoading: state is AuthLoadingState,
          child: AuthGlassCard(
            child:
                _isVerificationView
                    ? _buildVerificationContent(state)
                    : _buildRegistrationContent(errorMessage),
          ),
        );
      },
    );
  }

  Widget _buildRegistrationContent(String? errorMessage) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to continue',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.72),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          AuthStatusBanner(message: errorMessage),
        ],
        const SizedBox(height: 24),
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
              () => setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) => _validatePasswordMatch(),
        ),
        const SizedBox(height: 14),
        AuthInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          onToggleObscure:
              () => setState(() => _obscurePassword = !_obscurePassword),
          errorText: _passwordError,
          onChanged: (_) => _validatePasswordMatch(),
        ),
        const SizedBox(height: 20),
        AuthActionButton(
          label: 'Create Account',
          onPressed: _handleRegister,
          icon: Icons.person_add_alt_1,
        ),
        if (widget.onLoginTap != null) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: widget.onLoginTap,
            child: Text(
              'Already have an account? Sign In',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationContent(AuthState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final email = _emailController.text.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.onPrimary.withValues(alpha: 0.18),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: colorScheme.onPrimary,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Use the link we sent to\n$email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        const AuthStatusBanner(
          type: AuthStatusBannerType.info,
          message: 'After verifying, tap refresh to continue.',
        ),
        const SizedBox(height: 8),
        Text(
          "💡 Tip: Check your spam folder if you don't see the email.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 18),
        AuthActionButton(
          label: _resendButtonLabel,
          onPressed:
              _isResendPending || _timerSeconds > 0 ? null : _handleResend,
          style: AuthActionButtonStyle.subtle,
          isBusy: _isResendPending,
          icon: Icons.email,
        ),
        const SizedBox(height: 12),
        AuthActionButton(
          label: 'I Verified, Refresh',
          onPressed:
              state is AuthLoadingState
                  ? null
                  : () => context.read<AuthBloc>().add(
                    const RefreshCurrentUserEvent(isSilent: true),
                  ),
          icon: Icons.refresh,
        ),
        const SizedBox(height: 12),
        AuthActionButton(
          label: 'Sign Out',
          onPressed: () {
            context.read<AuthBloc>().add(const SignOutEvent());
            widget.onLoginTap?.call();
          },
          style: AuthActionButtonStyle.outline,
          icon: Icons.logout,
        ),
      ],
    );
  }

  String get _resendButtonLabel {
    if (_isResendPending) {
      return 'Sending...';
    }
    if (_timerSeconds > 0) {
      return 'Resend in $_timerSeconds s';
    }
    return 'Resend verification email';
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

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }

    setState(() {
      _passwordError = null;
    });

    context.read<AuthBloc>().add(
      RegisterWithEmailEvent(email: email, password: password),
    );
  }

  void _handleResend() {
    setState(() {
      _isResendPending = true;
    });
    context.read<AuthBloc>().add(const SendEmailVerificationEvent());
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _timerSeconds = 30);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_timerSeconds <= 1) {
        setState(() => _timerSeconds = 0);
        timer.cancel();
      } else {
        setState(() => _timerSeconds -= 1);
      }
    });
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
