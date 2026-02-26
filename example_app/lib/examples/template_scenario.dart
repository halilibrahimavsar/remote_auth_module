import 'package:flutter/material.dart';
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
      config: const AuthTemplateConfig(
        loginTitle: 'Secure Portal',
        logo: FlutterLogo(size: 64),
        showGoogleSignIn: true,
        showPhoneSignIn: true,
        showAnonymousSignIn: true,
      ),

      // This builder is called once the user is successfully authenticated.
      // This is where you transition to your main app content.
      authenticatedBuilder: (context, user) {
        return const AuthManagerPage();
      },
    );
  }
}
