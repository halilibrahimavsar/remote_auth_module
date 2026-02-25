import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

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
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true && context.mounted) {
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
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child:
                    user.photoURL == null
                        ? Text(
                          _getInitial(user.displayName ?? user.email),
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
              const SizedBox(height: 16),
              if (user.isAnonymous)
                const Chip(
                  label: Text('Guest Account'),
                  avatar: Icon(Icons.people_alt, size: 16),
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

  /// Safely extracts the first letter of a string.
  /// Handles null, empty, or whitespace strings gracefully.
  String _getInitial(String? text) {
    if (text == null) return '?';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    try {
      // Using characters to correctly handle emojis/unicode if present
      return trimmed.characters.first.toUpperCase();
    } catch (_) {
      // Fallback for any other string processing errors
      return '?';
    }
  }
}
