import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/theme/app_theme.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';

final _moodTrendProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getMoodTrend(30);
});

final _topTagsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getTopTags(10);
});

final _heatmapProvider = FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getActivityHeatmap();
});

final _timeOfDayProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getTimeOfDayDistribution();
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(title: 'Mood Trend (Last 30 Days)')
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          _MoodTrendChart(moodAsync: ref.watch(_moodTrendProvider))
              .animate(delay: 60.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Activity Heatmap')
              .animate(delay: 120.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          _ActivityHeatmap(heatmapAsync: ref.watch(_heatmapProvider))
              .animate(delay: 180.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Top Tags')
              .animate(delay: 240.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          _TopTagsChart(tagsAsync: ref.watch(_topTagsProvider))
              .animate(delay: 300.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Time of Day')
              .animate(delay: 360.ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 8),
          _TimeOfDayWidget(timeAsync: ref.watch(_timeOfDayProvider))
              .animate(delay: 420.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

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
              return const Center(child: Text('No mood data yet', style: TextStyle(color: Colors.white38)));
            }
            final spots = data.asMap().entries.map((entry) {
              final avgMood = (entry.value['avg_mood'] as num?)?.toDouble() ?? 3.0;
              return FlSpot(entry.key.toDouble(), avgMood);
            }).toList();

            return LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        const emojis = {1: '😞', 2: '😐', 3: '🙂', 4: '😊', 5: '🤩'};
                        return Text(emojis[val.toInt()] ?? '', style: const TextStyle(fontSize: 10));
                      },
                      interval: 1,
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final AsyncValue<Map<DateTime, int>> heatmapAsync;

  const _ActivityHeatmap({required this.heatmapAsync});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: heatmapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final now = DateTime.now();
          final weeks = 52;
          final today = DateTime(now.year, now.month, now.day);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  children: List.generate(weeks, (weekIdx) {
                    return Expanded(
                      child: Column(
                        children: List.generate(7, (dayIdx) {
                          final daysBack = (weeks - 1 - weekIdx) * 7 + (6 - dayIdx);
                          final date = today.subtract(Duration(days: daysBack));
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
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Less', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: _heatColor(i),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                  const SizedBox(width: 4),
                  const Text('More', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Color _heatColor(int count) {
    if (count == 0) return const Color(0xFF21262D);
    if (count == 1) return AppTheme.primary.withOpacity(0.3);
    if (count == 2) return AppTheme.primary.withOpacity(0.5);
    if (count == 3) return AppTheme.primary.withOpacity(0.7);
    return AppTheme.primary;
  }
}

class _TopTagsChart extends StatelessWidget {
  final AsyncValue<Map<String, int>> tagsAsync;

  const _TopTagsChart({required this.tagsAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tags yet', style: TextStyle(color: Colors.white38)),
              ),
            );
          }
          final sortedTags = tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final maxCount = sortedTags.first.value;
          return Column(
            children: sortedTags.take(8).map((entry) {
              final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                    Text('${entry.value}', style: Theme.of(context).textTheme.labelSmall),
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
    final cs = Theme.of(context).colorScheme;
    const timeIcons = {
      'Morning': '🌅',
      'Afternoon': '☀️',
      'Evening': '🌆',
      'Night': '🌙',
    };
    return GlassmorphismCard(
      padding: const EdgeInsets.all(16),
      child: timeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (timeData) {
          final total = timeData.values.fold(0, (a, b) => a + b);
          if (total == 0) {
            return const Center(child: Text('No data yet', style: TextStyle(color: Colors.white38)));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: timeData.entries.map((entry) {
              final pct = (entry.value / total * 100).round();
              return Column(
                children: [
                  Text(timeIcons[entry.key] ?? '⏰', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text('$pct%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary)),
                  Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
