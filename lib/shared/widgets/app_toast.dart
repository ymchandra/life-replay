import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/context_theme.dart';

enum AppToastType { info, success, warning, error }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final cs = context.appColors;

  IconData icon;
  Color accent;
  switch (type) {
    case AppToastType.success:
      icon = Iconsax.tick_circle;
      accent = cs.primary;
      break;
    case AppToastType.warning:
      icon = Iconsax.warning_2;
      accent = cs.secondary;
      break;
    case AppToastType.error:
      icon = Iconsax.close_circle;
      accent = cs.error;
      break;
    case AppToastType.info:
      icon = Iconsax.info_circle;
      accent = cs.primary;
      break;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.appText.bodySmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

