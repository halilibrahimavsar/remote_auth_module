import 'package:flutter/material.dart';

class BootstrapErrorPage extends StatelessWidget {
  final String error;

  const BootstrapErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Example Setup Needed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase initialization failed.',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(error),
            const SizedBox(height: 16),
            const Text(
              'For Web, configure Firebase options in one of these ways:\n'
              '1) Run FlutterFire CLI with web enabled.\n'
              '2) Pass dart-defines:\n'
              '   --dart-define=FIREBASE_WEB_API_KEY=...\n'
              '   --dart-define=FIREBASE_WEB_APP_ID=...\n'
              '   --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=...\n'
              '   --dart-define=FIREBASE_WEB_PROJECT_ID=...\n'
              '   --dart-define=FIREBASE_WEB_AUTH_DOMAIN=...\n'
              '   --dart-define=FIREBASE_WEB_STORAGE_BUCKET=...',
            ),
          ],
        ),
      ),
    );
  }
}
