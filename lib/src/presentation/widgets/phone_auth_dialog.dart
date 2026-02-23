import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_input_field.dart';

/// A dialog to handle phone number authentication.
class PhoneAuthDialog extends StatefulWidget {
  const PhoneAuthDialog({super.key});

  @override
  State<PhoneAuthDialog> createState() => _PhoneAuthDialogState();
}

class _PhoneAuthDialogState extends State<PhoneAuthDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String? _verificationId;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onVerifyPhone() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(VerifyPhoneNumberEvent(phoneNumber: phone));
  }

  void _onSignInWithCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty || _verificationId == null) return;

    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(
      SignInWithSmsCodeEvent(verificationId: _verificationId!, smsCode: code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PhoneCodeSentState) {
          setState(() {
            _verificationId = state.verificationId;
            _isLoading = false;
          });
        } else if (state is AuthErrorState) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthenticatedState) {
          Navigator.of(context).pop();
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: AuthGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShaderMask(
                    shaderCallback:
                        (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ).createShader(bounds),
                    child: Text(
                      _verificationId == null ? 'Phone Login' : 'Verify Code',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verificationId == null
                        ? 'Secure sign in with your number'
                        : 'Enter the 6-digit code sent to\n${_phoneController.text}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_verificationId == null) ...[
                    AuthInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      hintText: '+1 123 456 7890',
                    ),
                    const SizedBox(height: 24),
                    AuthActionButton(
                      label: 'Send Verification Code',
                      onPressed: _isLoading ? null : _onVerifyPhone,
                      isBusy: _isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ] else ...[
                    AuthInputField(
                      controller: _codeController,
                      label: '6-Digit Code',
                      icon: Icons.lock_clock_outlined,
                      keyboardType: TextInputType.number,
                      hintText: '000000',
                    ),
                    const SizedBox(height: 24),
                    AuthActionButton(
                      label: 'Confirm & Sign In',
                      onPressed: _isLoading ? null : _onSignInWithCode,
                      isBusy: _isLoading,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(() => _verificationId = null),
                      child: Text(
                        'Change Phone Number',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
}
