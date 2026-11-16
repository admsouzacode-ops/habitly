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
              _AchievementRows(
                builder: (tileWidth) => [
                  for (final a in achievements)
                    _AchievementTile(
                      achievement: a,
                      unlocked: unlocked(a),
                      value: progress[a.id] ?? 0,
                      unlockedAt: ledger.unlockedAt[a.id],
                      contentWidth: tileWidth - _AchievementTile.padding * 2,
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
    required this.contentWidth,
  });

  static const padding = 14.0;

  final Achievement achievement;
  final bool unlocked;
  final int value;
  final DateTime? unlockedAt;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shown = value > achievement.goal ? achievement.goal : value;
    return Card(
      key: ValueKey('achievement-${achievement.id}'),
      color: unlocked ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
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
            ),
            const SizedBox(height: 8),
            NoBreakTitle(
              achievement.title,
              maxWidth: contentWidth,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: unlocked ? null : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Spacer(),
            if (unlocked)
              Text(
                unlockedAt != null
                    ? 'Desde ${shortDateFormat.format(unlockedAt!)}'
                    : 'Desbloqueada',
                textAlign: TextAlign.center,
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
              Text(
                '$shown/${achievement.goal}',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Duas colunas; cada linha tem a altura do card mais alto (sem cortar texto).
class _AchievementRows extends StatelessWidget {
  const _AchievementRows({required this.builder});

  /// Recebe a largura de cada card.
  final List<Widget> Function(double tileWidth) builder;

  static const spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final children = builder(tileWidth);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

/// Título centralizado que quebra só entre palavras: se a palavra mais longa
/// não cabe em [maxWidth], a fonte diminui até caber (ex.: "Autoconhecimento").
class NoBreakTitle extends StatelessWidget {
  const NoBreakTitle(
    this.text, {
    super.key,
    required this.maxWidth,
    this.style,
    this.minScale = 0.6,
  });

  final String text;
  final double maxWidth;
  final TextStyle? style;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    var effective = base;
    if (maxWidth.isFinite && maxWidth > 0) {
      var widest = 0.0;
      for (final word in text.split(RegExp(r'\s+'))) {
        final tp = TextPainter(
          text: TextSpan(text: word, style: base),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (tp.width > widest) widest = tp.width;
        tp.dispose();
      }
      if (widest > maxWidth) {
        final scale = (maxWidth / widest * 0.97).clamp(minScale, 1.0);
        effective = base.copyWith(fontSize: (base.fontSize ?? 14) * scale);
      }
    }
    return Text(text, textAlign: TextAlign.center, style: effective);
  }
}
