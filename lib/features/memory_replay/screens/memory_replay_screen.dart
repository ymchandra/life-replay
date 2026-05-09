import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/models/life_phase.dart';
import 'package:life_replay/core/providers/chapter_replay_provider.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/services/location_service.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';
import 'package:life_replay/shared/widgets/location_chip.dart';
import 'package:life_replay/shared/widgets/mood_indicator.dart';
import 'package:life_replay/shared/widgets/tag_chip.dart';
import 'package:life_replay/shared/widgets/warm_hero_art.dart';

final _replaySessionProvider = StateProvider<_ReplaySession?>((ref) => null);
final _replayPageProvider = StateProvider<int>((ref) => 0);
final _isReplayingProvider = StateProvider<bool>((ref) => false);
final _replaySummaryProvider = StateProvider<_ReplaySummary?>((ref) => null);

enum _ReplayPreset { last7, last30, thisYear, onThisDay, bestMood, recentChapter }

class _ReplayFilter {
  final int minMood;
  final bool photosOnly;
  final bool locationOnly;
  final String? tag;

  const _ReplayFilter({
    this.minMood = 1,
    this.photosOnly = false,
    this.locationOnly = false,
    this.tag,
  });

  _ReplayFilter copyWith({
    int? minMood,
    bool? photosOnly,
    bool? locationOnly,
    String? tag,
    bool clearTag = false,
  }) {
    return _ReplayFilter(
      minMood: minMood ?? this.minMood,
      photosOnly: photosOnly ?? this.photosOnly,
      locationOnly: locationOnly ?? this.locationOnly,
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }
}

class _ReplayPreview {
  final int eventCount;
  final double avgMood;
  final List<String> topTags;
  final String firstTitle;
  final String lastTitle;
  final int withPhotos;
  final int withLocations;
  final List<double> moodSeries;

  const _ReplayPreview({
    required this.eventCount,
    required this.avgMood,
    required this.topTags,
    required this.firstTitle,
    required this.lastTitle,
    required this.withPhotos,
    required this.withLocations,
    required this.moodSeries,
  });
}

class _ReplaySession {
  final List<LifeEvent> events;
  final Map<int, List<String>> tagsByEventId;
  final _ReplayPreview preview;
  final String? chapterName;

  const _ReplaySession({
    required this.events,
    required this.tagsByEventId,
    required this.preview,
    this.chapterName,
  });
}

class _ReplaySummary {
  final int eventCount;
  final double avgMood;
  final List<String> topTags;
  final String moodArc;

  const _ReplaySummary({
    required this.eventCount,
    required this.avgMood,
    required this.topTags,
    required this.moodArc,
  });
}

class MemoryReplayScreen extends ConsumerStatefulWidget {
  const MemoryReplayScreen({super.key});

  @override
  ConsumerState<MemoryReplayScreen> createState() => _MemoryReplayScreenState();
}

class _MemoryReplayScreenState extends ConsumerState<MemoryReplayScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final _pageController = PageController();

  _ReplayFilter _filter = const _ReplayFilter();
  _ReplayPreview? _preview;
  bool _loadingPreview = false;
  bool _useOnThisDayMode = false;
  bool _bestMoodMode = false;
  List<String> _allTags = const [];
  _ReplayPreset? _selectedPreset;
  String? _presetSubtitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(databaseProvider);
      _allTags = await db.getAllTags();

      final chapterRange = ref.read(chapterReplayProvider);
      if (chapterRange != null) {
        setState(() {
          _startDate = chapterRange.start;
          _endDate = chapterRange.end;
          _selectedPreset = _ReplayPreset.recentChapter;
          _presetSubtitle = 'Replaying selected chapter';
        });
        ref.read(chapterReplayProvider.notifier).state = null;
        await _refreshPreview();
        await _loadAndReplay();
        return;
      }

      await _refreshPreview();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _applyPreset(_ReplayPreset preset) async {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      _useOnThisDayMode = false;
      _bestMoodMode = false;
      _presetSubtitle = null;
    });

    switch (preset) {
      case _ReplayPreset.last7:
        setState(() {
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
        });
      case _ReplayPreset.last30:
        setState(() {
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
        });
      case _ReplayPreset.thisYear:
        setState(() {
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
        });
      case _ReplayPreset.onThisDay:
        setState(() {
          _useOnThisDayMode = true;
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate;
          _presetSubtitle = 'Pulling memories from this same day across years';
        });
      case _ReplayPreset.bestMood:
        setState(() {
          _startDate = now.subtract(const Duration(days: 120));
          _endDate = now;
          _bestMoodMode = true;
          _presetSubtitle = 'Showing your highest-mood moments first';
        });
      case _ReplayPreset.recentChapter:
        final db = ref.read(databaseProvider);
        final phases = await db.getPhases();
        if (phases.isNotEmpty) {
          final chapter = phases.first;
          setState(() {
            _startDate = chapter.startDate;
            _endDate = chapter.endDate;
            _presetSubtitle = 'Recent chapter: ${chapter.name}';
          });
        }
    }

    await _refreshPreview();
  }

  Future<Map<int, List<String>>> _loadTagsForEvents(List<LifeEvent> events) async {
    final db = ref.read(databaseProvider);
    final tagsByEventId = <int, List<String>>{};
    final taggedEvents = events.where((e) => e.id != null).toList();
    final results = await Future.wait(
      taggedEvents.map((e) async => MapEntry(e.id!, await db.getTagsForEvent(e.id!))),
    );
    for (final entry in results) {
      tagsByEventId[entry.key] = entry.value;
    }
    return tagsByEventId;
  }

  List<LifeEvent> _applyFilters(List<LifeEvent> input, Map<int, List<String>> tagsByEventId) {
    var filtered = input.where((e) {
      final eventTags = e.id != null ? (tagsByEventId[e.id!] ?? const <String>[]) : const <String>[];
      final hasPhoto = e.photoPath != null && e.photoPath!.isNotEmpty;
      final hasLocation = e.latitude != null && e.longitude != null;
      final meetsTag = _filter.tag == null || eventTags.contains(_filter.tag);
      final meetsMood = e.mood >= _filter.minMood;
      return meetsMood &&
          (!_filter.photosOnly || hasPhoto) &&
          (!_filter.locationOnly || hasLocation) &&
          meetsTag;
    }).toList();

    if (_bestMoodMode) {
      filtered = filtered.where((e) => e.mood >= 4).toList();
    }
    return filtered;
  }

  _ReplayPreview _buildPreview(List<LifeEvent> events, Map<int, List<String>> tagsByEventId) {
    if (events.isEmpty) {
      return const _ReplayPreview(
        eventCount: 0,
        avgMood: 0,
        topTags: <String>[],
        firstTitle: '',
        lastTitle: '',
        withPhotos: 0,
        withLocations: 0,
        moodSeries: <double>[],
      );
    }

    final totalMood = events.fold<int>(0, (sum, e) => sum + e.mood);
    final photoCount = events.where((e) => e.photoPath != null && e.photoPath!.isNotEmpty).length;
    final locationCount = events.where((e) => e.latitude != null && e.longitude != null).length;

    final tagCounts = <String, int>{};
    for (final event in events) {
      final tags = event.id != null ? tagsByEventId[event.id!] ?? const <String>[] : const <String>[];
      for (final tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ReplayPreview(
      eventCount: events.length,
      avgMood: totalMood / events.length,
      topTags: topTags.take(4).map((e) => e.key).toList(),
      firstTitle: events.first.title,
      lastTitle: events.last.title,
      withPhotos: photoCount,
      withLocations: locationCount,
      moodSeries: events.map((e) => e.mood.toDouble()).toList(),
    );
  }

  Future<String?> _resolveChapterName(List<LifeEvent> events) async {
    if (events.isEmpty) return null;
    final db = ref.read(databaseProvider);
    final phases = await db.getPhases();
    if (phases.isEmpty) return null;

    final replayStart = events.first.timestamp;
    final replayEnd = events.last.timestamp;

    LifePhase? best;
    var bestOverlap = Duration.zero;
    for (final phase in phases) {
      final overlapStart = phase.startDate.isAfter(replayStart) ? phase.startDate : replayStart;
      final overlapEnd = phase.endDate.isBefore(replayEnd) ? phase.endDate : replayEnd;
      if (overlapEnd.isBefore(overlapStart)) continue;
      final overlap = overlapEnd.difference(overlapStart);
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        best = phase;
      }
    }

    return best?.name;
  }

  Future<_ReplaySession> _buildSession() async {
    final db = ref.read(databaseProvider);
    List<LifeEvent> events;

    if (_useOnThisDayMode) {
      events = await db.getEventsForDayAcrossYears(_endDate.month, _endDate.day);
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      events = await db.getEventsByDateRange(_startDate, _endDate);
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    final tagsByEventId = await _loadTagsForEvents(events);
    final filtered = _applyFilters(events, tagsByEventId);
    final preview = _buildPreview(filtered, tagsByEventId);
    final chapterName = await _resolveChapterName(filtered);

    return _ReplaySession(
      events: filtered,
      tagsByEventId: tagsByEventId,
      preview: preview,
      chapterName: chapterName,
    );
  }

  Future<void> _refreshPreview() async {
    setState(() => _loadingPreview = true);
    try {
      final session = await _buildSession();
      if (!mounted) return;
      setState(() => _preview = session.preview);
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _loadAndReplay() async {
    final session = await _buildSession();
    if (session.events.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No memories match these replay settings.')),
        );
      }
      return;
    }

    ref.read(_replaySessionProvider.notifier).state = session;
    ref.read(_replayPageProvider.notifier).state = 0;
    ref.read(_isReplayingProvider.notifier).state = true;
    ref.read(_replaySummaryProvider.notifier).state = null;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _useOnThisDayMode = false;
      _selectedPreset = null;
      _presetSubtitle = null;
    });
    await _refreshPreview();
  }

  _ReplaySummary _buildSummary(_ReplaySession session) {
    final moods = session.events.map((e) => e.mood).toList();
    final moodArc = moods.isEmpty
        ? 'Neutral replay arc'
        : moods.last > moods.first
            ? 'Mood improved across this replay'
            : moods.last < moods.first
                ? 'Mood dipped over this period'
                : 'Mood stayed fairly stable';
    return _ReplaySummary(
      eventCount: session.events.length,
      avgMood: session.preview.avgMood,
      topTags: session.preview.topTags,
      moodArc: moodArc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final isReplaying = ref.watch(_isReplayingProvider);
    final currentPage = ref.watch(_replayPageProvider);
    final session = ref.watch(_replaySessionProvider);
    final summary = ref.watch(_replaySummaryProvider);

    if (isReplaying && session != null) {
      return _ReplayView(
        session: session,
        currentPage: currentPage,
        pageController: _pageController,
        onClose: () {
          ref.read(_isReplayingProvider.notifier).state = false;
          ref.read(_replaySessionProvider.notifier).state = null;
          ref.read(_replayPageProvider.notifier).state = 0;
          ref.read(_replaySummaryProvider.notifier).state = null;
        },
        onPageChanged: (page) => ref.read(_replayPageProvider.notifier).state = page,
        onComplete: () {
          ref.read(_isReplayingProvider.notifier).state = false;
          ref.read(_replaySummaryProvider.notifier).state = _buildSummary(session);
        },
      );
    }

    if (summary != null) {
      return _ReplayCompleteView(
        summary: summary,
        onReplayAgain: () {
          ref.read(_replaySummaryProvider.notifier).state = null;
          _loadAndReplay();
        },
        onBackToSetup: () => ref.read(_replaySummaryProvider.notifier).state = null,
      );
    }

    return AppScaffold(
      title: 'Memory Replay',
      body: RefreshIndicator(
        onRefresh: _refreshPreview,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            const WarmHeroArt(variant: HeroArtVariant.replay, height: 180),
            const SizedBox(height: 20),
            Text('Reconstruct a period of your life', style: context.appText.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Replay memories like a film with filters, autoplay, and chapter-aware context.',
              style: context.appText.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),

            _PresetBar(selected: _selectedPreset, onTap: _applyPreset),
            if (_presetSubtitle != null) ...[
              const SizedBox(height: 8),
              Text(_presetSubtitle!, style: context.appText.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),

            GlassmorphismCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.calendar, size: 20, color: cs.primary),
                ),
                title: Text(
                  _useOnThisDayMode
                      ? 'On this day: ${DateFormat('MMMM d').format(_endDate)}'
                      : '${DateFormat('MMM d, yyyy').format(_startDate)} → ${DateFormat('MMM d, yyyy').format(_endDate)}',
                  style: context.appText.titleSmall,
                ),
                subtitle: Text(
                  _useOnThisDayMode
                      ? 'Across all years in your timeline'
                      : '${_endDate.difference(_startDate).inDays + 1} days',
                  style: context.appText.labelSmall,
                ),
                trailing: const Icon(Iconsax.edit, size: 18),
                onTap: _pickDateRange,
              ),
            ),

            const SizedBox(height: 12),
            _ReplayFiltersCard(
              filter: _filter,
              allTags: _allTags,
              onChanged: (next) async {
                setState(() => _filter = next);
                await _refreshPreview();
              },
            ),

            const SizedBox(height: 12),
            _ReplayPreviewCard(preview: _preview, loading: _loadingPreview),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_preview?.eventCount ?? 0) > 0 && !_loadingPreview ? _loadAndReplay : null,
                icon: const Icon(Iconsax.play),
                label: Text(
                  (_preview?.eventCount ?? 0) > 0
                      ? 'Start Replay (${_preview!.eventCount} events)'
                      : 'No matching memories',
                ),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'Tip: enable autoplay inside replay and adjust speed for a cinematic flow.',
              textAlign: TextAlign.center,
              style: context.appText.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ).animate(delay: 260.ms).fadeIn(duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _PresetBar extends StatelessWidget {
  final _ReplayPreset? selected;
  final ValueChanged<_ReplayPreset> onTap;

  const _PresetBar({required this.selected, required this.onTap});

  String _label(_ReplayPreset preset) {
    switch (preset) {
      case _ReplayPreset.last7:
        return 'Last 7d';
      case _ReplayPreset.last30:
        return 'Last 30d';
      case _ReplayPreset.thisYear:
        return 'This Year';
      case _ReplayPreset.onThisDay:
        return 'On This Day';
      case _ReplayPreset.bestMood:
        return 'Best Mood';
      case _ReplayPreset.recentChapter:
        return 'Recent Chapter';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ReplayPreset.values
            .map(
              (preset) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_label(preset)),
                  selected: selected == preset,
                  onSelected: (_) => onTap(preset),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReplayFiltersCard extends StatelessWidget {
  final _ReplayFilter filter;
  final List<String> allTags;
  final ValueChanged<_ReplayFilter> onChanged;

  const _ReplayFiltersCard({
    required this.filter,
    required this.allTags,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.filter, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text('Replay Filters', style: context.appText.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Mood >= ${filter.minMood}'),
                selected: filter.minMood > 1,
                onSelected: (_) => onChanged(filter.copyWith(minMood: filter.minMood == 5 ? 1 : filter.minMood + 1)),
              ),
              FilterChip(
                label: const Text('Photos only'),
                selected: filter.photosOnly,
                onSelected: (v) => onChanged(filter.copyWith(photosOnly: v)),
              ),
              FilterChip(
                label: const Text('Locations only'),
                selected: filter.locationOnly,
                onSelected: (v) => onChanged(filter.copyWith(locationOnly: v)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: filter.tag,
            decoration: const InputDecoration(
              labelText: 'Tag focus (optional)',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Any tag')),
              ...allTags.map((t) => DropdownMenuItem<String?>(value: t, child: Text('#$t'))),
            ],
            onChanged: (v) => onChanged(filter.copyWith(tag: v, clearTag: v == null)),
          ),
        ],
      ),
    );
  }
}

class _ReplayPreviewCard extends StatelessWidget {
  final _ReplayPreview? preview;
  final bool loading;

  const _ReplayPreviewCard({required this.preview, required this.loading});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return GlassmorphismCard(
      child: loading
          ? const SizedBox(height: 130, child: Center(child: CircularProgressIndicator()))
          : (preview == null || preview!.eventCount == 0)
              ? SizedBox(
                  height: 130,
                  child: Center(
                    child: Text(
                      'No memories in this selection.\nTry broadening dates or filters.',
                      textAlign: TextAlign.center,
                      style: context.appText.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(label: 'Events', value: '${preview!.eventCount}'),
                        ),
                        Expanded(
                          child: _StatTile(label: 'Avg Mood', value: '${preview!.avgMood.toStringAsFixed(1)}/5'),
                        ),
                        Expanded(
                          child: _StatTile(label: 'Photos', value: '${preview!.withPhotos}'),
                        ),
                        Expanded(
                          child: _StatTile(label: 'Locations', value: '${preview!.withLocations}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MiniSparkline(points: preview!.moodSeries, color: cs.primary),
                    const SizedBox(height: 10),
                    Text('Starts: ${preview!.firstTitle}', style: context.appText.labelSmall),
                    Text('Ends: ${preview!.lastTitle}', style: context.appText.labelSmall),
                    if (preview!.topTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: preview!.topTags.map((t) => TagChip(label: t, compact: true)).toList(),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return Column(
      children: [
        Text(value, style: context.appText.titleMedium),
        Text(label, style: context.appText.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _ReplayView extends StatefulWidget {
  final _ReplaySession session;
  final int currentPage;
  final PageController pageController;
  final VoidCallback onClose;
  final VoidCallback onComplete;
  final ValueChanged<int> onPageChanged;

  const _ReplayView({
    required this.session,
    required this.currentPage,
    required this.pageController,
    required this.onClose,
    required this.onPageChanged,
    required this.onComplete,
  });

  @override
  State<_ReplayView> createState() => _ReplayViewState();
}

class _ReplayViewState extends State<_ReplayView> {
  Timer? _autoPlayTimer;
  bool _autoPlay = false;
  double _speedSeconds = 2.5;

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    if (_autoPlay) {
      _startAutoPlay();
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(Duration(milliseconds: (_speedSeconds * 1000).round()), (_) {
      if (widget.currentPage >= widget.session.events.length - 1) {
        _autoPlayTimer?.cancel();
        setState(() => _autoPlay = false);
        widget.onComplete();
        return;
      }
      widget.pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  String _milestoneText(double progress) {
    if (progress >= 1) return 'Replay complete';
    if (progress >= 0.75) return 'Final chapter';
    if (progress >= 0.5) return 'Halfway through your story';
    if (progress >= 0.25) return 'Momentum is building';
    return 'Replay started';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final events = widget.session.events;
    final currentPage = widget.currentPage;
    final progress = events.isEmpty ? 0.0 : (currentPage + 1) / events.length;

    return AppScaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Iconsax.close_circle, color: cs.onSurfaceVariant),
                        onPressed: widget.onClose,
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: cs.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${currentPage + 1}/${events.length}', style: context.appText.labelSmall),
                    ],
                  ),
                  if (widget.session.chapterName != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Chapter: ${widget.session.chapterName}',
                        style: context.appText.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_milestoneText(progress), style: context.appText.labelMedium),
                  ),
                  const SizedBox(height: 6),
                  _MiniSparkline(points: widget.session.preview.moodSeries, color: cs.primary),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: widget.pageController,
                onPageChanged: widget.onPageChanged,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final tags = event.id != null
                      ? widget.session.tagsByEventId[event.id!] ?? const <String>[]
                      : const <String>[];
                  return _EventPage(event: event, tags: tags);
                },
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _NavButton(
                          icon: Iconsax.arrow_left,
                          enabled: currentPage > 0,
                          onTap: currentPage > 0
                              ? () => widget.pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _toggleAutoPlay,
                            icon: Icon(_autoPlay ? Iconsax.pause : Iconsax.play),
                            label: Text(_autoPlay ? 'Pause Auto-play' : 'Auto-play'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _NavButton(
                          icon: currentPage < events.length - 1 ? Iconsax.arrow_right : Iconsax.tick_circle,
                          enabled: true,
                          onTap: () {
                            if (currentPage < events.length - 1) {
                              widget.pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              widget.onComplete();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Speed: ', style: context.appText.labelSmall),
                        for (final speed in const [2.5, 1.8, 1.2])
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text('${(2.5 / speed).toStringAsFixed(1)}x'),
                              selected: _speedSeconds == speed,
                              onSelected: (_) {
                                setState(() => _speedSeconds = speed);
                                if (_autoPlay) _startAutoPlay();
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(icon, color: cs.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _EventPage extends StatelessWidget {
  final LifeEvent event;
  final List<String> tags;

  const _EventPage({required this.event, required this.tags});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final hasPhoto = event.photoPath != null && event.photoPath!.isNotEmpty && File(event.photoPath!).existsSync();
    final hasLocation = event.latitude != null && event.longitude != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
      children: [
        MoodIndicator(mood: event.mood, size: 44).animate().fadeIn(duration: 380.ms),
        const SizedBox(height: 14),
        Text(
          event.title,
          style: context.appText.headlineMedium?.copyWith(
                color: cs.onBackground,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 460.ms).slideY(begin: 0.1, end: 0),

        if (hasPhoto) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(event.photoPath!),
              fit: BoxFit.cover,
              height: 220,
              width: double.infinity,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
        ],

        if (event.content.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            event.content,
            style: context.appText.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.65,
                ),
            textAlign: TextAlign.center,
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
        ],

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: tags.take(8).map((t) => TagChip(label: t, compact: true)).toList(),
          ),
        ],

        if (hasLocation) ...[
          const SizedBox(height: 12),
          Center(
            child: LocationChip(
              locationName: event.locationName,
              coordinates: LocationService.formatCoordinates(event.latitude!, event.longitude!),
            ),
          ),
        ],

        const SizedBox(height: 20),
        Text(
          DateFormat('EEEE, MMMM d, yyyy  ·  h:mm a').format(event.timestamp),
          textAlign: TextAlign.center,
          style: context.appText.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.35,
          ),
        ).animate(delay: 240.ms).fadeIn(duration: 380.ms),
      ],
    );
  }
}

class _ReplayCompleteView extends StatelessWidget {
  final _ReplaySummary summary;
  final VoidCallback onReplayAgain;
  final VoidCallback onBackToSetup;

  const _ReplayCompleteView({
    required this.summary,
    required this.onReplayAgain,
    required this.onBackToSetup,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return AppScaffold(
      title: 'Replay Complete',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const WarmHeroArt(variant: HeroArtVariant.insights, height: 180),
          const SizedBox(height: 18),
          Text('Replay complete', style: context.appText.headlineSmall),
          const SizedBox(height: 8),
          Text(
            summary.moodArc,
            style: context.appText.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          GlassmorphismCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session insights', style: context.appText.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'Events', value: '${summary.eventCount}')),
                    Expanded(child: _StatTile(label: 'Avg Mood', value: '${summary.avgMood.toStringAsFixed(1)}/5')),
                  ],
                ),
                if (summary.topTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: summary.topTags.map((t) => TagChip(label: t, compact: true)).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onReplayAgain,
            icon: const Icon(Iconsax.play),
            label: const Text('Replay Again'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onBackToSetup,
            icon: const Icon(Iconsax.setting_2),
            label: const Text('Adjust Replay Setup'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share memory card is coming soon.')),
              );
            },
            icon: const Icon(Iconsax.share),
            label: const Text('Share Memory Card'),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> points;
  final Color color;

  const _MiniSparkline({required this.points, required this.color});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 30);
    }
    return SizedBox(
      height: 30,
      child: CustomPaint(
        painter: _SparklinePainter(points: points, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  const _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minY = points.reduce((a, b) => a < b ? a : b);
    final maxY = points.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalized = (points[i] - minY) / range;
      final y = size.height - (normalized * (size.height - 2)) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

