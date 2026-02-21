import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import '../pages/home_page.dart';

class AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const AuthGate({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading indicator while checking auth state
        if (state is AuthInitialState || state is AuthLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // authenticated -> Show Home Page
        if (state is AuthenticatedState) {
          return HomePage(
            user: state.user,
            onToggleTheme: onToggleTheme,
            isDarkMode: isDarkMode,
          );
        }

        // Email verification required
        if (state is EmailVerificationRequiredState) {
          return EmailVerificationPage(user: state.user);
        }

        // Unauthenticated -> Show Login Page from the module
        return LoginPage(
          onRegisterTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: RegisterPage(
                        onLoginTap: () => Navigator.of(context).pop(),
                      ),
                    ),
              ),
            );
          },
          onForgotPasswordTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: const ForgotPasswordPage(),
                    ),
              ),
            );
          },
          onAuthenticated: (_) {},
        );
      },
    );
  }
}
