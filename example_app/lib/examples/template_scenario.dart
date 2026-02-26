import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

/// A scenario demonstrating the use of the [RemoteAuthFlow] template.
///
/// This is the easiest way to implement auth. It handles all auth pages
/// (Login, Register, Forgot Password, Verification) within a single widget.
class TemplateScenario extends StatelessWidget {
  const TemplateScenario({super.key});

  @override
  Widget build(BuildContext context) {
    return RemoteAuthFlow(
      // Optional: Pass an AuthBloc if you use DI (get_it, etc.)
      // authBloc: getIt<AuthBloc>(),
      loginTitle: 'Secure Portal',
      logo: const FlutterLogo(size: 64),
      showGoogleSignIn: false,
      showPhoneSignIn: false,
      showAnonymousSignIn: false,

      // This builder is called once the user is successfully authenticated.
      // This is where you transition to your main app content.
      authenticatedBuilder: (context, user) {
        return Scaffold(
          appBar: AppBar(title: const Text('Main Application')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome, ${user.displayName ?? user.email}!'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      () => context.read<AuthBloc>().add(const SignOutEvent()),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
