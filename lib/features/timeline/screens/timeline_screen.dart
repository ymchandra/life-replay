import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/ingestion/passive_ingestion.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/services/passive_memory_sync_service.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/timeline/widgets/grid_timeline_view.dart';
import 'package:life_replay/features/timeline/widgets/linear_timeline_view.dart';
import 'package:life_replay/features/timeline/widgets/on_this_day_banner.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
import 'package:life_replay/shared/widgets/app_toast.dart';
import 'package:life_replay/shared/widgets/empty_state.dart';

enum TimelineViewMode { linear, grid }

final timelineViewModeProvider =
    StateProvider<TimelineViewMode>((ref) => TimelineViewMode.linear);

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with WidgetsBindingObserver {
  final Map<int, List<String>> _tagCache = {};
  double _headerScrollOffset = 0;
  bool _syncingPassiveSources = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncGalleryMemories();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncGalleryMemories();
    }
  }

  Future<void> _syncGalleryMemories() async {
    if (_syncingPassiveSources) return;
    _syncingPassiveSources = true;
    try {
      final db = ref.read(databaseProvider);
      final summary = await PassiveMemorySyncService.syncAllSources(db);
      if (summary.hasMeaningfulChanges) {
        await ref.read(eventsProvider.notifier).loadEvents();
        if (mounted) {
          final sourceBreakdown = summary.importedBySource.entries
              .map((e) => '${e.value} ${_pluralizeSourceLabel(e.key.label, e.value)}')
              .join(', ');
          showAppToast(
            context,
            'Imported ${summary.imported} memories${summary.merged > 0 ? ' and merged ${summary.merged}' : ''}'
            '${sourceBreakdown.isNotEmpty ? ' ($sourceBreakdown)' : ''}',
            type: AppToastType.success,
          );
        }
      }
    } finally {
      _syncingPassiveSources = false;
    }
  }

  Future<void> _showPassiveSourceSettings() async {
    final current = await PassiveMemorySyncService.getEnabledSources();
    if (!mounted) return;
    final selected = Map<MemorySourceType, bool>.from(current);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Passive source privacy controls'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: selected.entries.map((entry) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key.label),
                    subtitle: Text(entry.value ? 'Enabled' : 'Disabled'),
                    value: entry.value,
                    onChanged: (next) {
                      setLocalState(() {
                        selected[entry.key] = next;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  for (final item in selected.entries) {
                    await PassiveMemorySyncService.setSourceEnabled(item.key, item.value);
                  }
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _pluralizeSourceLabel(String label, int count) {
    if (count == 1) return label.toLowerCase();
    if (label.endsWith('s')) return label.toLowerCase();
    return '${label.toLowerCase()}s';
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final next = notification.metrics.pixels.clamp(0, 96).toDouble();
    if ((next - _headerScrollOffset).abs() < 1.5) return false;
    if (mounted) {
      setState(() {
        _headerScrollOffset = next;
      });
    }
    return false;
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _consecutiveStreak(List<LifeEvent> events) {
    if (events.isEmpty) return 0;
    final uniqueDays = events
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    var streak = 1;
    for (var i = 1; i < uniqueDays.length; i++) {
      final diff = uniqueDays[i - 1].difference(uniqueDays[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _loadTagsForEvents(List<dynamic> events, DatabaseHelper db) async {
    for (final event in events) {
      if (event.id != null && !_tagCache.containsKey(event.id)) {
        final tags = await db.getTagsForEvent(event.id!);
        if (mounted) {
          setState(() {
            _tagCache[event.id!] = tags;
          });
        }
      }
    }
  }

  void _openEventEditor() {
    context.push('/event/new');
  }

  void _navigateToEvent(dynamic event) {
    if (event.id != null) {
      context.push('/event/${event.id}');
    }
  }

  Future<void> _deleteEvent(dynamic event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Memory'),
        content: Text('Delete "${event.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && event.id != null) {
      await ref.read(eventsProvider.notifier).deleteEvent(event.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final viewMode = ref.watch(timelineViewModeProvider);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    final totalEvents = eventsAsync.maybeWhen(
      data: (events) => events.length,
      orElse: () => 0,
    );
    final monthEvents = eventsAsync.maybeWhen(
      data: (events) => events
          .cast<LifeEvent>()
          .where((e) => e.timestamp.year == now.year && e.timestamp.month == now.month)
          .length,
      orElse: () => 0,
    );
    final streak = eventsAsync.maybeWhen(
      data: (events) => _consecutiveStreak(events.cast<LifeEvent>()),
      orElse: () => 0,
    );

    return AppScaffold(
      titleWidget: _JourneyAppBarHeader(
        greeting: _timeGreeting(),
        monthEventCount: monthEvents,
        totalEventCount: totalEvents,
        streakDays: streak,
        scrollOffset: _headerScrollOffset,
      ),
      actions: [
        IconButton(
          tooltip: 'Passive source controls',
          icon: const Icon(Icons.settings_outlined),
          onPressed: _showPassiveSourceSettings,
        ),
        IconButton(
          tooltip: viewMode == TimelineViewMode.linear
              ? 'Switch to grid view'
              : 'Switch to timeline view',
          icon: Icon(
            viewMode == TimelineViewMode.linear ? Iconsax.grid_2 : Iconsax.menu,
          ),
          onPressed: () {
            ref.read(timelineViewModeProvider.notifier).state =
                viewMode == TimelineViewMode.linear
                    ? TimelineViewMode.grid
                    : TimelineViewMode.linear;
          },
        ),
      ],
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              icon: Iconsax.clock,
              title: 'No memories yet',
              subtitle: 'Passive import runs in background. Tap + to add a memory manually.',
            );
          }

          _loadTagsForEvents(events, db);
          final grouped = app_date_utils.groupEventsByDate(events);

          return Column(
            children: [
              const OnThisDayBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: viewMode == TimelineViewMode.linear
                        ? LinearTimelineView(
                            groupedEvents: grouped,
                            tagCache: _tagCache,
                            onEventTap: _navigateToEvent,
                            onEventEdit: _navigateToEvent,
                            onEventDelete: _deleteEvent,
                          )
                        : GridTimelineView(
                            groupedEvents: grouped,
                            tagCache: _tagCache,
                            onEventTap: _navigateToEvent,
                            onEventEdit: _navigateToEvent,
                            onEventDelete: _deleteEvent,
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'timeline_add_event_fab',
        onPressed: _openEventEditor,
        child: const Icon(Iconsax.add),
      ),
    );
  }
}

class _JourneyAppBarHeader extends StatelessWidget {
  final String greeting;
  final int monthEventCount;
  final int totalEventCount;
  final int streakDays;
  final double scrollOffset;

  const _JourneyAppBarHeader({
    required this.greeting,
    required this.monthEventCount,
    required this.totalEventCount,
    required this.streakDays,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][now.month - 1];

    final t = (scrollOffset / 72).clamp(0.0, 1.0);
    final titleSize = lerpDouble(22, 18, t)!;
    final subtitleOpacity = 1 - t;
    final sparkleSize = lerpDouble(16, 14, t)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(top: lerpDouble(2, 0, t)!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: sparkleSize),
              const SizedBox(width: 6),
              Text(
                'Journey',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: titleSize),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: subtitleOpacity < 0.08
                ? const SizedBox.shrink()
                : Opacity(
                    opacity: subtitleOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$greeting · $month ${now.day} · $monthEventCount this month · $totalEventCount total · $streakDays-day streak',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
