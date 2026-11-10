import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/providers/providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitSnapshotProvider);
    final ledger = ref.watch(achievementLedgerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar: $e')),
        data: (snapshot) {
          final today = DateTime.now();
          final progress = achievementProgress(snapshot, today);
          final computed = computeUnlocked(snapshot, today);
          bool unlocked(Achievement a) =>
              computed.contains(a.id) || ledger.isUnlocked(a.id);
          final count = achievements.where(unlocked).length;
          final scheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count de ${achievements.length} conquistas',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: count / achievements.length,
                                minHeight: 8,
                                backgroundColor: scheme.surface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
                children: [
                  for (final a in achievements)
                    _AchievementTile(
                      achievement: a,
                      unlocked: unlocked(a),
                      value: progress[a.id] ?? 0,
                      unlockedAt: ledger.unlockedAt[a.id],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.value,
    this.unlockedAt,
  });

  final Achievement achievement;
  final bool unlocked;
  final int value;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shown = value > achievement.goal ? achievement.goal : value;
    return Card(
      key: ValueKey('achievement-${achievement.id}'),
      color: unlocked ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: unlocked
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.surfaceContainerHighest,
              child: Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(
                  achievement.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: unlocked ? null : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                achievement.description,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ),
            if (unlocked)
              Text(
                unlockedAt != null
                    ? 'Desde ${shortDateFormat.format(unlockedAt!)}'
                    : 'Desbloqueada',
                style: textTheme.labelSmall?.copyWith(color: scheme.primary),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: achievement.goal == 0 ? 0 : shown / achievement.goal,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text('$shown/${achievement.goal}', style: textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}
