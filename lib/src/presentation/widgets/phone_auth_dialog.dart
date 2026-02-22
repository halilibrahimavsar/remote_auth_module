import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PhoneCodeSentState) {
          setState(() {
            _verificationId = state.verificationId;
            _isLoading = false;
          });
        } else if (state is AuthErrorState) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AuthenticatedState) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _verificationId == null ? 'Phone Login' : 'Enter Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_verificationId == null) ...[
                AuthInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  hintText: '+1 123 456 7890',
                ),
                const SizedBox(height: 24),
                AuthActionButton(
                  label: 'Send Code',
                  onPressed: _isLoading ? null : _onVerifyPhone,
                  isBusy: _isLoading,
                ),
              ] else ...[
                Text(
                  'A code was sent to ${_phoneController.text}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AuthInputField(
                  controller: _codeController,
                  label: 'Verification Code',
                  icon: Icons.sms_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                AuthActionButton(
                  label: 'Verify & Login',
                  onPressed: _isLoading ? null : _onSignInWithCode,
                  isBusy: _isLoading,
                ),
                TextButton(
                  onPressed: () => setState(() => _verificationId = null),
                  child: const Text('Change Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
