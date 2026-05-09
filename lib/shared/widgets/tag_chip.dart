import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/context_theme.dart';

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final bool compact;

  const TagChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    if (onDeleted != null) {
      return InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Iconsax.close_circle, size: 14),
        backgroundColor: cs.primary.withOpacity(0.15),
        labelStyle: TextStyle(color: cs.primary, fontSize: 12),
        side: BorderSide(color: cs.primary.withOpacity(0.3)),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
            : null,
      );
    }
    return Chip(
      label: Text(label),
      backgroundColor: cs.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: cs.primary, fontSize: 12),
      side: BorderSide(color: cs.primary.withOpacity(0.2)),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
          : null,
    );
  }
}
