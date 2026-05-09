import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/context_theme.dart';

class LocationChip extends StatelessWidget {
  final String? locationName;
  final String? coordinates;
  final VoidCallback? onClear;
  final bool isLoading;

  const LocationChip({
    super.key,
    this.locationName,
    this.coordinates,
    this.onClear,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (locationName == null && coordinates == null) {
      return const SizedBox.shrink();
    }

    final cs = context.appColors;
    final displayText = locationName ?? coordinates ?? 'Unknown location';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.location,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.appText.labelSmall?.copyWith(
                color: cs.onSurface,
              ),
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: isLoading ? null : onClear,
              child: Icon(
                Iconsax.close_circle,
                size: 16,
                color: cs.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

