import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_bloc_auth/firebase_bloc_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Bloc.observer = const AuthBlocObserver();

  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final FirebaseAuthRepository _authRepository;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    // Create the repository with your preferred configuration.
    // serverClientId is the "Web client" OAuth 2.0 Client ID from
    // Google Cloud Console → APIs & Services → Credentials.
    // It is REQUIRED on Android for Google Sign-In v7.
    _authRepository = FirebaseAuthRepository(
      auth: fb.FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      serverClientId:
          '789348142189-58e9t524q6pk14a67pk21lasvogudlaj.apps.googleusercontent.com',
      createUserCollection: true,
    );
    _authBloc = AuthBloc(repository: _authRepository)
      ..add(const InitializeAuthEvent());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp(
        title: 'Firebase Auth Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D2671),
            secondary: const Color(0xFFC33764),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Listens to auth state and shows the appropriate page.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthenticatedState) {
          return HomePage(user: state.user);
        }
        if (state is AuthLoadingState || state is AuthInitialState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Unauthenticated or error → show login
        return LoginPage(
          onRegisterTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: RegisterPage(
                        onLoginTap: () => Navigator.pop(context),
                      ),
                    ),
              ),
            );
          },
          onForgotPasswordTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: const ForgotPasswordPage(),
                    ),
              ),
            );
          },
          onAuthenticated: (_) {
            // AuthGate will automatically show HomePage via BlocBuilder
          },
        );
      },
    );
  }
}

class AuthBlocObserver extends BlocObserver {
  const AuthBlocObserver();

  @override
  void onEvent(Bloc bloc, Object? event) {
    log(
      '[${bloc.runtimeType}] Event: $event',
      name: 'firebase_bloc_auth.example',
    );
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    log(
      '[${bloc.runtimeType}] Transition: $transition',
      name: 'firebase_bloc_auth.example',
    );
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log(
      '[${bloc.runtimeType}] Error',
      name: 'firebase_bloc_auth.example',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

/// Simple authenticated home page.
class HomePage extends StatelessWidget {
  final AuthUser user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showAuthConfirmDialog(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                confirmLabel: 'Log Out',
                icon: Icons.logout,
                confirmColor: theme.colorScheme.error,
              );
              if (confirmed && context.mounted) {
                context.read<AuthBloc>().add(const SignOutEvent());
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child:
                  user.photoURL == null
                      ? Text(
                        (user.displayName ?? user.email)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? 'User',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
