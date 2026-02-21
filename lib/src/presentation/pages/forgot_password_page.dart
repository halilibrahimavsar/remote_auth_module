import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_gradient_scaffold.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_input_field.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';

class ForgotPasswordPage extends StatefulWidget {
  final VoidCallback? onResetSent;

  const ForgotPasswordPage({super.key, this.onResetSent});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordResetSentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset email sent.'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          widget.onResetSent?.call();
          if (widget.onResetSent == null) {
            Navigator.of(context).maybePop();
          }
        } else if (state is AuthErrorState) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email and we'll send reset instructions.",
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
                const SizedBox(height: 18),
                AuthActionButton(
                  label: 'Send Reset Email',
                  onPressed: _sendReset,
                  icon: Icons.send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendReset() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email is required.');
      return;
    }

    final isValidEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!isValidEmail) {
      _showError('Please enter a valid email address.');
      return;
    }

    context.read<AuthBloc>().add(SendPasswordResetEvent(email: email));
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
