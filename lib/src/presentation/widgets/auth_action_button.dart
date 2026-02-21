import 'package:flutter/material.dart';

enum AuthActionButtonStyle { primary, outline, subtle }

class AuthActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AuthActionButtonStyle style;
  final bool isBusy;
  final IconData? icon;

  const AuthActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AuthActionButtonStyle.primary,
    this.isBusy = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null || isBusy;

    final background = switch (style) {
      AuthActionButtonStyle.primary => colorScheme.onPrimary,
      AuthActionButtonStyle.outline => Colors.transparent,
      AuthActionButtonStyle.subtle => colorScheme.onPrimary.withValues(
        alpha: 0.1,
      ),
    };

    final border = switch (style) {
      AuthActionButtonStyle.primary => const BorderSide(
        color: Colors.transparent,
      ),
      AuthActionButtonStyle.outline => BorderSide(
        color: colorScheme.onPrimary.withValues(alpha: 0.85),
      ),
      AuthActionButtonStyle.subtle => BorderSide(
        color: colorScheme.onPrimary.withValues(alpha: 0.2),
      ),
    };

    final foreground = switch (style) {
      AuthActionButtonStyle.primary => colorScheme.primary,
      AuthActionButtonStyle.outline ||
      AuthActionButtonStyle.subtle => colorScheme.onPrimary,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled ? 0.55 : 1,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: style == AuthActionButtonStyle.primary ? 8 : 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: background,
            foregroundColor: foreground,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            side: border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: disabled ? null : onPressed,
          child:
              isBusy
                  ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foreground),
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
