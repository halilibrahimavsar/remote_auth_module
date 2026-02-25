import 'package:flutter/widgets.dart';

/// Configuration for all auth flow templates.
///
/// Controls which authentication methods are visible and customizes
/// the text shown in the UI. Every template (Default, Aurora, Wave, Neon)
/// reads from this config so the consumer only configures once.
class AuthTemplateConfig {
  const AuthTemplateConfig({
    this.showGoogleSignIn = true,
    this.showPhoneSignIn = true,
    this.showAnonymousSignIn = true,
    this.showRegister = true,
    this.showForgotPassword = true,
    this.showRememberMe = true,
    this.loginTitle = 'Welcome Back',
    this.loginSubtitle = 'Sign in to continue',
    this.registerTitle = 'Create Account',
    this.registerSubtitle = 'Create your account to continue',
    this.logo,
  });

  /// Whether to show the Google Sign-In button.
  final bool showGoogleSignIn;

  /// Whether to show the Phone Sign-In option.
  final bool showPhoneSignIn;

  /// Whether to show the Guest/Anonymous Sign-In option.
  final bool showAnonymousSignIn;

  /// Whether to show the "Sign Up" navigation link.
  final bool showRegister;

  /// Whether to show the "Forgot Password" link.
  final bool showForgotPassword;

  /// Whether to show the "Remember Me" checkbox.
  final bool showRememberMe;

  /// Title displayed on the login page.
  final String loginTitle;

  /// Subtitle displayed on the login page.
  final String loginSubtitle;

  /// Title displayed on the register page.
  final String registerTitle;

  /// Subtitle displayed on the register page.
  final String registerSubtitle;

  /// Optional logo widget shown at the top of the login page.
  final Widget? logo;
}
