import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/shared/widgets/mood_indicator.dart';

final _onThisDayBannerProvider = FutureProvider.autoDispose<List<LifeEvent>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  // Only return past-year memories (not events from this year's same day)
  final all = await db.getEventsForDayAcrossYears(now.month, now.day);
  return all.where((e) => e.timestamp.year < now.year).toList();
});

/// A compact "On This Day" card shown at the top of the timeline feed
/// when there are matching memories from past years on today's date.
class OnThisDayBanner extends ConsumerStatefulWidget {
  const OnThisDayBanner({super.key});

  @override
  ConsumerState<OnThisDayBanner> createState() => _OnThisDayBannerState();
}

class _OnThisDayBannerState extends ConsumerState<OnThisDayBanner> {
  bool _expanded = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final eventsAsync = ref.watch(_onThisDayBannerProvider);

    return eventsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        final cs = context.appColors;
        final now = DateTime.now();
        final dateLabel = DateFormat('MMMM d').format(now);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.12),
                    cs.secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row — always visible
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          const Text('✨',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'On This Day  ·  $dateLabel',
                                  style: context.appText.labelMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${events.length} memor${events.length == 1 ? 'y' : 'ies'} from past year${events.length == 1 ? '' : 's'}',
                                  style: context.appText.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _expanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _dismissed = true),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Iconsax.close_circle,
                                  size: 16, color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded memory list
                  if (_expanded) ...[
                    Divider(
                        height: 1,
                        color: cs.primary.withOpacity(0.15)),
                    ...events.take(5).map((e) => _MemoryRow(event: e)),
                    if (events.length > 5)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Text(
                          '+ ${events.length - 5} more',
                          style: context.appText.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(
              begin: -0.06,
              end: 0,
              duration: 350.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _MemoryRow extends StatelessWidget {
  final LifeEvent event;
  const _MemoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final yearsAgo = DateTime.now().year - event.timestamp.year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodIndicator(mood: event.mood, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: context.appText.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$yearsAgo year${yearsAgo > 1 ? 's' : ''} ago  ·  ${DateFormat('MMM d, y').format(event.timestamp)}',
                  style: context.appText.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

