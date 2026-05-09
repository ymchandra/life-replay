import 'package:flutter/material.dart';
import 'package:life_replay/core/theme/app_theme.dart';
import 'package:life_replay/core/theme/context_theme.dart';

class MoodIndicator extends StatelessWidget {
  final int mood;
  final double size;
  final bool showEmoji;

  const MoodIndicator({
    super.key,
    required this.mood,
    this.size = 20,
    this.showEmoji = true,
  });

  Color _moodColor(BuildContext context) {
    return AppTheme.moodColor(mood, fallback: context.appColors.onSurfaceVariant);
  }

  String get _emoji {
    switch (mood) {
      case 1:
        return '😞';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '🙂';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showEmoji) {
      return Text(_emoji, style: TextStyle(fontSize: size));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _moodColor(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _moodColor(context).withOpacity(0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
