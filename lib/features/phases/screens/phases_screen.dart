import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/models/life_phase.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/phases_provider.dart';
import 'package:life_replay/shared/widgets/empty_state.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';

class PhasesScreen extends ConsumerWidget {
  const PhasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(phasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Phases'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => ref.read(phasesProvider.notifier).loadPhases(),
          ),
        ],
      ),
      body: phasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (phases) {
          if (phases.isEmpty) {
            return const EmptyState(
              imagePath: 'assets/images/hero_phases.png',
              title: 'No phases detected yet',
              subtitle:
                  'Add more memories and life phases will be automatically detected based on your activity patterns.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: phases.length,
            itemBuilder: (context, index) {
              return _PhaseCard(
                phase: phases[index],
                animIndex: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _PhaseCard extends ConsumerWidget {
  final LifePhase phase;
  final int animIndex;

  const _PhaseCard({required this.phase, required this.animIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final db = ref.read(databaseProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _phaseColor(phase.phaseType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(phase.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(phase.name, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${DateFormat('MMM d, yyyy').format(phase.startDate)} – ${DateFormat('MMM d, yyyy').format(phase.endDate)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _phaseColor(phase.phaseType).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${phase.duration.inDays}d',
              style: TextStyle(
                color: _phaseColor(phase.phaseType),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(phase.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  FutureBuilder<List<LifeEvent>>(
                    future: db.getEventsByDateRange(phase.startDate, phase.endDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final events = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${events.length} events in this phase',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary),
                          ),
                          const SizedBox(height: 8),
                          ...events.take(3).map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Iconsax.record, size: 10, color: Colors.white38),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.title,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (events.length > 3)
                            Text(
                              '+ ${events.length - 3} more',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animIndex * 80))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05, end: 0, duration: 350.ms);
  }

  Color _phaseColor(String phaseType) {
    switch (phaseType) {
      case 'work':
        return const Color(0xFF6366F1);
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'social':
        return const Color(0xFFF59E0B);
      case 'creative':
        return const Color(0xFF8B5CF6);
      case 'recovery':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
