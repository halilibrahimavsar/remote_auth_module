import 'package:flutter/material.dart';

enum AuthStatusBannerType { error, success, info }

class AuthStatusBanner extends StatelessWidget {
  final String message;
  final AuthStatusBannerType type;

  const AuthStatusBanner({
    super.key,
    required this.message,
    this.type = AuthStatusBannerType.error,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final accent = switch (type) {
      AuthStatusBannerType.error => colorScheme.error,
      AuthStatusBannerType.success => const Color(0xFF22C55E),
      AuthStatusBannerType.info => colorScheme.onPrimary,
    };

    final icon = switch (type) {
      AuthStatusBannerType.error => Icons.error_outline,
      AuthStatusBannerType.success => Icons.check_circle_outline,
      AuthStatusBannerType.info => Icons.info_outline,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
