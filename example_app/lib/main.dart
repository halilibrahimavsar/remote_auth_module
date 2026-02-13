import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final AuthRepository _authRepository;
  late final AuthBloc _authBloc;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize the repository from the module.
    // Ensure you provide the correct serverClientId for Google Sign-In on Android.
    _authRepository = FirebaseAuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      createUserCollection: true,
      // Replace with your actual Web Client ID from Google Cloud Console
      serverClientId: '789348142189-58e9t524q6pk14a67pk21lasvogudlaj.apps.googleusercontent.com',
    );

    _authBloc = AuthBloc(repository: _authRepository)
      ..add(const InitializeAuthEvent());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp(
        title: 'Remote Auth Module Example',
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D2671),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D2671),
            brightness: Brightness.dark,
          ),
        ),
        home: AuthGate(
          onToggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}

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
           return Scaffold(
             appBar: AppBar(title: const Text('Verify Email')),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text('Please verify your email: ${state.user.email}'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () {
                       context.read<AuthBloc>().add(const SendEmailVerificationEvent());
                     },
                     child: const Text('Resend Verification Email'),
                   ),
                   TextButton(
                     onPressed: () {
                         context.read<AuthBloc>().add(const SignOutEvent());
                     },
                     child: const Text('Sign Out'),
                   )
                 ],
               ),
             ),
           );
        }

        // Unauthenticated -> Show Login Page from the module
        return LoginPage(
          onRegisterTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
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
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: const ForgotPasswordPage(),
                ),
              ),
            );
          },
          // Optional: You can handle successful login here if needed
          // but AuthGate will automatically rebuild when state changes to Authenticated.
          onAuthenticated: (user) {
             // Already handled by BlocBuilder
          },
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.user,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.photoURL != null 
                    ? NetworkImage(user.photoURL!) 
                    : null,
                child: user.photoURL == null
                    ? Text(
                        (user.displayName ?? user.email).substring(0, 1).toUpperCase(),
                        style: theme.textTheme.displaySmall,
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user.displayName ?? 'User'}!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text('UID: ${user.id}'),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('This is a dummy action')),
                   );
                },
                icon: const Icon(Icons.check),
                label: const Text('Perform Action'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
