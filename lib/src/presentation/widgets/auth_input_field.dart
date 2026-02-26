import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthInputField extends StatefulWidget {
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
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusAnim;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusAnim.forward();
      } else {
        _focusAnim.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusAnim.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (context, child) {
        final v = _focusAnim.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.onPrimary.withValues(alpha: 0.1 + 0.04 * v),
            border: Border.all(
              color:
                  widget.errorText == null
                      ? Color.lerp(
                        colorScheme.onPrimary.withValues(alpha: 0.26),
                        colorScheme.onPrimary.withValues(alpha: 0.55),
                        v,
                      )!
                      : colorScheme.error.withValues(alpha: 0.5),
              width: 1.0 + v * 0.5,
            ),
            boxShadow:
                v > 0.01
                    ? [
                      BoxShadow(
                        color: colorScheme.onPrimary.withValues(
                          alpha: 0.06 * v,
                        ),
                        blurRadius: 12 * v,
                        spreadRadius: 1 * v,
                      ),
                    ]
                    : null,
          ),
          child: child!,
        );
      },
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        inputFormatters: widget.inputFormatters,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.72),
          ),
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.4),
          ),
          errorText: widget.errorText,
          errorStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          prefixIcon:
              widget.prefix ??
              Icon(
                widget.icon,
                color: colorScheme.onPrimary.withValues(alpha: 0.84),
              ),
          suffixIcon:
              widget.onToggleObscure == null
                  ? null
                  : IconButton(
                    onPressed: widget.onToggleObscure,
                    icon: Icon(
                      widget.obscureText
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
