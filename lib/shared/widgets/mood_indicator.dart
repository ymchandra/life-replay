import 'package:flutter/material.dart';

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
    switch (mood) {
      case 1:
        return const Color(0xFFF85149);
      case 2:
        return const Color(0xFFF0883E);
      case 3:
        return const Color(0xFFD29922);
      case 4:
        return const Color(0xFF3FB950);
      case 5:
        return const Color(0xFF58A6FF);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
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
