import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    required this.controller,
    required this.label,
    required this.icon,
    super.key,
    this.obscureText = false,
    this.onToggleObscure,
    this.errorText,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
    this.hintText,
    this.prefix,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.onPrimary.withValues(alpha: 0.1),
        border: Border.all(
          color:
              errorText == null
                  ? colorScheme.onPrimary.withValues(alpha: 0.26)
                  : colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        style: TextStyle(color: colorScheme.onPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.72),
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onPrimary.withValues(alpha: 0.4),
          ),
          errorText: errorText,
          errorStyle: TextStyle(color: colorScheme.error),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          prefixIcon:
              prefix ??
              Icon(icon, color: colorScheme.onPrimary.withValues(alpha: 0.84)),
          suffixIcon:
              onToggleObscure == null
                  ? null
                  : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
        ),
      ),
    );
  }
}
