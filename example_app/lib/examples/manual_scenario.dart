import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

/// A scenario demonstrating manual integration of auth states.
///
/// Use this if you need full control over the layout or if you want
/// to use your own custom login/home widgets while keeping the module's logic.
class ManualIntegrationScenario extends StatelessWidget {
  const ManualIntegrationScenario({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitialState || state is AuthLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthenticatedState) {
          return CustomHomeScreen(user: state.user);
        }

        if (state is EmailVerificationRequiredState) {
          return EmailVerificationPage(user: state.user);
        }

        // Default to Login Page if Unauthenticated
        return LoginPage(
          title: 'Custom Integration',
          onRegisterTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (ctx) => BlocProvider.value(
                        value: context.read<AuthBloc>(),
                        child: RegisterPage(
                          onLoginTap: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                ),
              ),
        );
      },
    );
  }
}

class CustomHomeScreen extends StatelessWidget {
  final AuthUser user;
  const CustomHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user,
              size: 80,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'User ID: ${user.id}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              onPressed:
                  () => context.read<AuthBloc>().add(const SignOutEvent()),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
