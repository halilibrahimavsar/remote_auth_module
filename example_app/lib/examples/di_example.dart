import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

/// An example of how to configure the repository for different environments.
///
/// This file illustrates the use of [FirebaseAuthRepository] parameters
/// to enable features like Firestore sync.
class DIConfigurationExample {
  static AuthRepository provideRepository() {
    return FirebaseAuthRepository(
      // 1. Enable Firestore Sync
      // Automatically creates/updates user docs in the 'users' collection
      createUserCollection: true,

      // 2. Multi-App support
      // Optional: Pass a custom FirebaseAuth/Firestore instance
      // auth: FirebaseAuth.instanceFor(app: secondaryApp),

      // 3. Android Support
      // Required for Google Sign-In to work on Android
      serverClientId:
          '789348142189-58e9t524q6pk14a67pk21lasvogudlaj.apps.googleusercontent.com',

      // 4. Custom Collection Name
      usersCollectionName: 'app_users',
    );
  }

  static AuthBloc provideAuthBloc(AuthRepository repository) {
    return AuthBloc(repository: repository)..add(const InitializeAuthEvent());
  }
}

/// A simple widget to show the setup in action
class DIExamplePage extends StatelessWidget {
  const DIExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = DIConfigurationExample.provideRepository();

    return BlocProvider(
      create: (_) => DIConfigurationExample.provideAuthBloc(repo),
      child: RemoteAuthFlow(
        authenticatedBuilder:
            (context, user) => Scaffold(
              appBar: AppBar(title: const Text('DI Success')),
              body: Center(child: Text('Authenticated as: ${user.email}')),
            ),
      ),
    );
  }
}
