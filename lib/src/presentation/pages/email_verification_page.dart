import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/src/presentation/bloc/auth_bloc.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_action_button.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_glass_card.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_gradient_scaffold.dart';
import 'package:remote_auth_module/src/presentation/widgets/auth_status_banner.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    this.user,
    this.onAuthenticated,
    this.onSignedOut,
  });
  final AuthUser? user;
  final void Function(AuthUser user)? onAuthenticated;
  final VoidCallback? onSignedOut;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  AuthUser? _user;
  bool _isResendPending = false;
  int _cooldownSeconds = 0;
  Timer? _timer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _user = widget.user;

    // Auto-refresh timer: check for verification status every 5 seconds.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted &&
          context.read<AuthBloc>().state is EmailVerificationRequiredState) {
        context.read<AuthBloc>().add(
          const RefreshCurrentUserEvent(isSilent: true),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailVerificationRequiredState) {
          setState(() {
            _isResendPending = false;
          });
          if (_user?.id != state.user.id) {
            setState(() => _user = state.user);
          }
          return;
        }

        if (state is EmailVerificationSentState) {
          setState(() => _isResendPending = false);
          _startCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification email sent.'),
              backgroundColor: colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (state is AuthenticatedState) {
          widget.onAuthenticated?.call(state.user);
          if (widget.onAuthenticated == null &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
          return;
        }

        if (state is UnauthenticatedState) {
          widget.onSignedOut?.call();
          if (widget.onSignedOut == null && Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
          return;
        }

        if (state is AuthErrorState) {
          setState(() => _isResendPending = false);
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
        final email = _user?.email ?? 'your email address';

        return AuthGradientScaffold(
          showBackButton: true,
          isLoading: state is AuthLoadingState,
          child: AuthGlassCard(
            child: Column(
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
                    Icons.mark_email_unread_outlined,
                    color: colorScheme.onPrimary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
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
                  'We sent a verification link to\n$email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                const AuthStatusBanner(
                  type: AuthStatusBannerType.info,
                  message: 'Open your inbox, verify, then tap refresh.',
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
                  label: _resendLabel,
                  onPressed:
                      _isResendPending || _cooldownSeconds > 0
                          ? null
                          : _handleResend,
                  isBusy: _isResendPending,
                  style: AuthActionButtonStyle.subtle,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                AuthActionButton(
                  label: 'Refresh Status',
                  onPressed:
                      state is AuthLoadingState
                          ? null
                          : () => context.read<AuthBloc>().add(
                            const RefreshCurrentUserEvent(),
                          ),
                  icon: Icons.refresh,
                ),
                const SizedBox(height: 12),
                AuthActionButton(
                  label: 'Sign Out',
                  onPressed:
                      state is AuthLoadingState
                          ? null
                          : () => context.read<AuthBloc>().add(
                            const SignOutEvent(),
                          ),
                  style: AuthActionButtonStyle.outline,
                  icon: Icons.logout,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _resendLabel {
    if (_isResendPending) {
      return 'Sending...';
    }
    if (_cooldownSeconds > 0) {
      return 'Resend in $_cooldownSeconds s';
    }
    return 'Resend email';
  }

  void _handleResend() {
    setState(() => _isResendPending = true);
    context.read<AuthBloc>().add(const SendEmailVerificationEvent());
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldownSeconds = 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_cooldownSeconds <= 1) {
        setState(() => _cooldownSeconds = 0);
        timer.cancel();
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }
}
