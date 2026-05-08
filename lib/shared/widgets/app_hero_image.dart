import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A full-width hero image displayed at the top of a screen or section.
/// The [assetPath] must be a registered asset in pubspec.yaml.
class AppHeroImage extends StatelessWidget {
  final String assetPath;
  final double height;
  final BorderRadius? borderRadius;

  const AppHeroImage({
    super.key,
    required this.assetPath,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
