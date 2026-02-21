import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_gradient_scaffold.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_input_field.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isSubmitting = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PasswordUpdatedState) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password updated. Signing out...'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).maybePop();
          return;
        }

        if (state is UnauthenticatedState || state is AuthErrorState) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
          }
        }

        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
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
                    'Change Password',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your current password to set a new one.',
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
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    icon: Icons.lock_clock_outlined,
                    obscureText: _hideCurrent,
                    onToggleObscure:
                        () => setState(() => _hideCurrent = !_hideCurrent),
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    icon: Icons.lock_outline,
                    obscureText: _hideNew,
                    onToggleObscure: () => setState(() => _hideNew = !_hideNew),
                    onChanged: (_) => _validateConfirmMatch(),
                  ),
                  const SizedBox(height: 14),
                  AuthInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_reset_outlined,
                    obscureText: _hideConfirm,
                    onToggleObscure:
                        () => setState(() => _hideConfirm = !_hideConfirm),
                    errorText: _confirmError,
                    onChanged: (_) => _validateConfirmMatch(),
                  ),
                  const SizedBox(height: 20),
                  AuthActionButton(
                    label: 'Update Password',
                    onPressed: _isSubmitting ? null : _submit,
                    isBusy: _isSubmitting,
                    icon: Icons.password,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _validateConfirmMatch() {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      if (confirm.isNotEmpty && confirm != newPassword) {
        _confirmError = 'Passwords do not match';
      } else {
        _confirmError = null;
      }
    });
  }

  void _submit() {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please complete all fields.');
      return;
    }

    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _confirmError = 'Passwords do not match');
      return;
    }

    setState(() {
      _confirmError = null;
      _isSubmitting = true;
    });

    context.read<AuthBloc>().add(
      UpdatePasswordEvent(
        currentPassword: currentPassword,
        newPassword: newPassword,
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
