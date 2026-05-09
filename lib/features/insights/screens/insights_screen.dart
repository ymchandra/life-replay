import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/models/life_phase.dart';
import 'package:life_replay/core/providers/chapter_replay_provider.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/phases_provider.dart';
import 'package:life_replay/core/theme/app_theme.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
import 'package:life_replay/shared/widgets/empty_state.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';

// ── Analytics data providers ────────────────────────────────────────────────

final _moodTrendProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(databaseProvider).getMoodTrend(30);
});

final _topTagsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(databaseProvider).getTopTags(10);
});

final _heatmapProvider = FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  return ref.watch(databaseProvider).getActivityHeatmap();
});

final _timeOfDayProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(databaseProvider).getTimeOfDayDistribution();
});

// ── Screen ───────────────────────────────────────────────────────────────────

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.appColors;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Insights',
        body: Column(
          children: [
            // Sub-tab bar
            Container(
              color: cs.surface,
              child: TabBar(
                indicatorColor: cs.primary,
                indicatorWeight: 2.5,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: context.appText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: context.appText.labelLarge,
                tabs: const [
                  Tab(text: 'Analytics'),
                  Tab(text: 'Chapters'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AnalyticsTab(ref: ref),
                  _ChaptersTab(ref: ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analytics tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _SectionTitle(title: 'Mood Trend — Last 30 Days').animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        _MoodTrendChart(moodAsync: ref.watch(_moodTrendProvider))
            .animate(delay: 60.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Activity Heatmap').animate(delay: 120.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        _ActivityHeatmap(heatmapAsync: ref.watch(_heatmapProvider))
            .animate(delay: 180.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Top Tags').animate(delay: 240.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        _TopTagsChart(tagsAsync: ref.watch(_topTagsProvider))
            .animate(delay: 300.ms).fadeIn(duration: 350.ms),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Time of Day').animate(delay: 360.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 8),
        _TimeOfDayWidget(timeAsync: ref.watch(_timeOfDayProvider))
            .animate(delay: 420.ms).fadeIn(duration: 350.ms),
      ],
    );
  }
}

// ── Chapters tab ──────────────────────────────────────────────────────────────

class _ChaptersTab extends ConsumerWidget {
  const _ChaptersTab({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(phasesProvider);

    return phasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (phases) {
        if (phases.isEmpty) {
          return const EmptyState(
            icon: Iconsax.book,
            title: 'No chapters yet',
            subtitle:
                'Chapters appear automatically once you have at least 2 memories in a week.\n\nKeep journaling — your life story is taking shape!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: phases.length,
          itemBuilder: (context, index) =>
              _PhaseCard(phase: phases[index], animIndex: index),
        );
      },
    );
  }
}

// ── Shared section title ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: context.appText.titleMedium),
      ],
    );
  }
}

// ── Phase card ────────────────────────────────────────────────────────────────

class _PhaseCard extends ConsumerWidget {
  final LifePhase phase;
  final int animIndex;

  const _PhaseCard({required this.phase, required this.animIndex});

  Color _phaseColor(String type) {
    switch (type) {
      case 'work':     return const Color(0xFF6366F1);
      case 'travel':   return const Color(0xFF06B6D4);
      case 'social':   return const Color(0xFFF59E0B);
      case 'creative': return const Color(0xFF8B5CF6);
      case 'recovery': return const Color(0xFF10B981);
      default:         return const Color(0xFF6B7280);
    }
  }

  String _moodEmojiFrom(double mood) {
    if (mood >= 4.5) return '🤩';
    if (mood >= 3.5) return '😊';
    if (mood >= 2.5) return '🙂';
    if (mood >= 1.5) return '😐';
    return '😞';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.appColors;
    final db = ref.read(databaseProvider);
    final accent = _phaseColor(phase.phaseType);
    final durationDays = phase.duration.inDays + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(phase.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(phase.name,
                            style: context.appText.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          '${DateFormat('MMM d').format(phase.startDate)} – ${DateFormat('MMM d, yyyy').format(phase.endDate)}',
                          style: context.appText.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Duration badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${durationDays}d',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Mood + stats bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Text(
                    _moodEmojiFrom(phase.avgMood),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'avg mood ${phase.avgMood.toStringAsFixed(1)}',
                    style: context.appText.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(Iconsax.clock, size: 12,
                      color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${phase.eventCount} memories',
                    style: context.appText.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // ── Description ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                phase.description,
                style: context.appText.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              ),
            ),

            // ── Top tags ─────────────────────────────────────────────────────
            if (phase.topTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: phase.topTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accent.withOpacity(0.25)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600),
                    ),
                  )).toList(),
                ),
              ),

            // ── Expandable memories preview ───────────────────────────────────
            Theme(
              data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'View memories in this chapter',
                  style: context.appText.labelMedium
                      ?.copyWith(color: cs.primary),
                ),
                trailing:
                    Icon(Iconsax.arrow_down_1, size: 16, color: cs.primary),
                children: [
                  FutureBuilder<List<LifeEvent>>(
                    future: db.getEventsByDateRange(
                        phase.startDate, phase.endDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final events = snapshot.data!;
                      return Padding(
                        padding:
                            const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            ...events.take(5).map((e) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Iconsax.record,
                                          size: 10,
                                          color: accent),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.title,
                                              style: context
                                                  .appText.bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              DateFormat('MMM d')
                                                  .format(e.timestamp),
                                              style: context.appText
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: cs
                                                          .onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            if (events.length > 5)
                              Text('+ ${events.length - 5} more',
                                  style: context.appText.labelSmall
                                      ?.copyWith(
                                          color: cs.onSurfaceVariant)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Replay this chapter button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Iconsax.play, size: 16, color: accent),
                  label: Text('Replay this Chapter',
                      style: TextStyle(color: accent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ref.read(chapterReplayProvider.notifier).state =
                        DateTimeRange(
                      start: phase.startDate,
                      end: phase.endDate,
                    );
                    context.go('/memory-replay');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: animIndex * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.04, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

// ── Analytics chart widgets (migrated from analytics_screen.dart) ────────────

class _MoodTrendChart extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> moodAsync;
  const _MoodTrendChart({required this.moodAsync});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: moodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Text('No mood data yet',
                    style: TextStyle(color: context.appColors.onSurfaceVariant)));
            }
            final spots = data.asMap().entries.map((e) {
              final avgMood = (e.value['avg_mood'] as num?)?.toDouble() ?? 3.0;
              return FlSpot(e.key.toDouble(), avgMood);
            }).toList();

            return LineChart(LineChartData(
              minY: 1,
              maxY: 5,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (val, _) {
                      const emojis = {1: '😞', 2: '😐', 3: '🙂', 4: '😊', 5: '🤩'};
                      return Text(emojis[val.toInt()] ?? '', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final AsyncValue<Map<DateTime, int>> heatmapAsync;
  const _ActivityHeatmap({required this.heatmapAsync});

  Color _heatColor(int count) {
    if (count == 0) return const Color(0xFF21262D);
    if (count == 1) return AppTheme.primary.withOpacity(0.3);
    if (count == 2) return AppTheme.primary.withOpacity(0.5);
    if (count == 3) return AppTheme.primary.withOpacity(0.7);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: heatmapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  children: List.generate(52, (w) => Expanded(
                    child: Column(
                      children: List.generate(7, (d) {
                        final daysBack = (52 - 1 - w) * 7 + (6 - d);
                        final date = todayDate.subtract(Duration(days: daysBack));
                        final count = data[date] ?? 0;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: _heatColor(count),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Less',
                      style: TextStyle(color: context.appColors.onSurfaceVariant, fontSize: 10)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) => Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: _heatColor(i),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                  const SizedBox(width: 4),
                  Text('More',
                      style: TextStyle(color: context.appColors.onSurfaceVariant, fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopTagsChart extends StatelessWidget {
  final AsyncValue<Map<String, int>> tagsAsync;
  const _TopTagsChart({required this.tagsAsync});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No tags yet',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            );
          }
          final sorted = tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final maxCount = sorted.first.value;
          return Column(
            children: sorted.take(8).map((entry) {
              final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(entry.key, style: context.appText.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}', style: context.appText.labelSmall),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TimeOfDayWidget extends StatelessWidget {
  final AsyncValue<Map<String, int>> timeAsync;
  const _TimeOfDayWidget({required this.timeAsync});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    const icons = {'Morning': '🌅', 'Afternoon': '☀️', 'Evening': '🌆', 'Night': '🌙'};
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: timeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (timeData) {
          final total = timeData.values.fold(0, (a, b) => a + b);
          if (total == 0) {
            return Center(child: Text('No data yet',
                style: TextStyle(color: cs.onSurfaceVariant)));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: timeData.entries.map((entry) {
              final pct = (entry.value / total * 100).round();
              return Column(
                children: [
                  Text(icons[entry.key] ?? '⏰', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text('$pct%',
                      style: context.appText.titleSmall?.copyWith(color: cs.primary)),
                  Text(entry.key, style: context.appText.labelSmall),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

