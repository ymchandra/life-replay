import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/theme/app_theme.dart';

/// A lightweight bottom sheet for capturing a memory in under 5 seconds.
/// Type a note, tap the send button — done.
/// For richer editing, tap "More options" to open the full editor.
class QuickCaptureSheet extends ConsumerStatefulWidget {
  static const int _defaultMood = 3;     // neutral on the 1–5 scale
  static const int _titleMaxChars = 57;  // chars before truncation with "…"
  final VoidCallback? onSaved;

  const QuickCaptureSheet({super.key, this.onSaved});

  @override
  ConsumerState<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<QuickCaptureSheet> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _deriveTitle(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Memory';
    // Use first line, or first 60 characters
    final firstLine = trimmed.split('\n').first.trim();
    if (firstLine.length <= QuickCaptureSheet._titleMaxChars + 3) return firstLine;
    return '${firstLine.substring(0, QuickCaptureSheet._titleMaxChars)}…';
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final event = LifeEvent(
        title: _deriveTitle(text),
        content: text,
        mood: QuickCaptureSheet._defaultMood,
        timestamp: DateTime.now(),
      );
      await ref.read(eventsProvider.notifier).addEvent(event, []);
      widget.onSaved?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openFullEditor() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/event/new');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppTheme.divider),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Label
              Text(
                'Capture a memory',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              // Text input
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'What's on your mind right now?',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              // Actions row
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _openFullEditor,
                    icon: Icon(Iconsax.edit_2, size: 16, color: cs.onSurfaceVariant),
                    label: Text(
                      'More options',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  const Spacer(),
                  // Send button
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: AppTheme.background,
                      minimumSize: const Size(56, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Iconsax.send_1, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
