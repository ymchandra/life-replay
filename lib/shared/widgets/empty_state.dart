import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    this.action,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath!,
                  width: 280,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              )
                  .animate(
                      onPlay: (controller) =>
                          controller.repeat(reverse: true))
                  .scaleXY(
                    begin: 0.97,
                    end: 1.0,
                    duration: 2200.ms,
                    curve: Curves.easeInOut,
                  )
            else
              Icon(icon, size: 80, color: cs.onSurfaceVariant.withOpacity(0.4))
                  .animate(
                      onPlay: (controller) =>
                          controller.repeat(reverse: true))
                  .scaleXY(
                    begin: 0.92,
                    end: 1.0,
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                  ),
              textAlign: TextAlign.center,
            ).animate(delay: 80.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ).animate(delay: 160.ms).fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!
                  .animate(delay: 240.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.15, end: 0),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

