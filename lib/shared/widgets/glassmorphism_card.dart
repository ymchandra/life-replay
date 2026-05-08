import 'package:flutter/material.dart';

/// A warm, matte surface card — replaces the previous glassmorphism/blur card.
/// Keeps the same API so all existing callers continue to work unchanged.
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  // blurSigma kept for API compatibility but no longer used
  final double blurSigma;
  final Color? borderColor;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.blurSigma = 0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? cs.onSurface.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
