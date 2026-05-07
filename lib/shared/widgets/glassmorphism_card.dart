import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final Color? borderColor;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.blurSigma = 8,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? cs.onSurface.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
