import 'dart:ui';

import 'package:flutter/material.dart';

class AuthGradientScaffold extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthGradientScaffold({
    super.key,
    required this.child,
    this.isLoading = false,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          _GlowOrb(
            alignment: const Alignment(-0.9, -0.75),
            color: colorScheme.onPrimary.withValues(alpha: 0.12),
            size: 260,
          ),
          _GlowOrb(
            alignment: const Alignment(0.95, 0.9),
            color: colorScheme.onPrimary.withValues(alpha: 0.09),
            size: 300,
          ),
          SafeArea(
            child: Stack(
              children: [
                if (showBackButton)
                  Positioned(
                    top: 6,
                    left: 4,
                    child: IconButton(
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.26),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: size,
                spreadRadius: size * 0.15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
