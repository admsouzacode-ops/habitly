import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/habit_form_screen.dart';

/// Detalhes de um hábito: meta, sequência atual e recorde, totais e os
/// últimos dias/semanas.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitSnapshotProvider);
    final snapshot = async.valueOrNull;
    final habit = snapshot?.habits.where((h) => h.id == habitId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(habit?.name ?? 'Hábito'),
        actions: [
          if (habit != null)
            IconButton(
              tooltip: 'Editar hábito',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => HabitFormScreen(habit: habit),
                  ),
                );
                // Excluído no formulário: volta para a lista.
                if (changed == true && context.mounted) {
                  final still = ref
                      .read(habitSnapshotProvider)
                      .valueOrNull
                      ?.habits
                      .any((h) => h.id == habitId);
                  if (still == false) Navigator.of(context).maybePop();
                }
              },
            ),
        ],
      ),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : habit == null
          ? const Center(child: Text('Hábito não encontrado.'))
          : _DetailBody(snapshot: snapshot, habitId: habitId),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.snapshot, required this.habitId});

  final HabitSnapshot snapshot;
  final int habitId;

  @override
  Widget build(BuildContext context) {
    final habit = snapshot.habits.firstWhere((h) => h.id == habitId);
    final today = dateOnly(DateTime.now());
    final goal = snapshot.goalFor(habit);
    final streak = snapshot.streakOf(habit, today);
    final total = snapshot.completions
        .where((c) => c.habitId == habitId)
        .length;
    final presence = [snapshot.presenceOf(habit)];
    final month = completionRate(
      habits: presence,
      today: today,
      windowDays: 30,
    );
    final color = Color(habit.colorValue);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(habit.icon, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Chip(
                    avatar: Icon(_goalIcon(goal.type), size: 18),
                    label: Text(goal.summary()),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                emoji: '🔥',
                label: 'Sequência atual',
                value: '${streak.current}',
                hint: streak.label(streak.current),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                emoji: '🏆',
                label: 'Recorde',
                value: '${streak.best}',
                hint: streak.label(streak.best),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                emoji: '✅',
                label: 'Conclusões',
                value: '$total',
                hint: 'no total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStat(
                emoji: '📈',
                label: 'Taxa em 30 dias',
                value: '${month.percent}%',
                hint: '${month.completed} de ${month.scheduled}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          goal.isWeekly ? 'Últimas 8 semanas' : 'Últimos 14 dias',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: goal.isWeekly
                ? _WeeksStrip(
                    snapshot: snapshot,
                    habitId: habitId,
                    target: goal.safeWeeklyTarget,
                    today: today,
                    color: color,
                  )
                : _DaysStrip(
                    snapshot: snapshot,
                    habitId: habitId,
                    goal: goal,
                    today: today,
                    color: color,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          goal.isWeekly
              ? 'A sequência conta semanas seguidas com a meta batida. A '
                    'semana atual só entra quando você bate a meta.'
              : 'A sequência conta os dias agendados seguidos. Dias fora da '
                    'agenda não quebram a sequência.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  IconData _goalIcon(GoalType type) => switch (type) {
    GoalType.daily => Icons.event_repeat_outlined,
    GoalType.weekly => Icons.date_range_outlined,
    GoalType.quantity => Icons.straighten_outlined,
  };
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.hint,
  });

  final String emoji;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(label, style: textTheme.labelMedium),
            Text(value, style: textTheme.headlineMedium),
            Text(hint, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DaysStrip extends StatelessWidget {
  const _DaysStrip({
    required this.snapshot,
    required this.habitId,
    required this.goal,
    required this.today,
    required this.color,
  });

  final HabitSnapshot snapshot;
  final int habitId;
  final HabitGoal goal;
  final DateTime today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = [for (var i = 13; i >= 0; i--) addDays(today, -i)];
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      children: [
        for (final d in days)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: snapshot.isCompleted(habitId, d)
                      ? color
                      : goal.availableOn(d)
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: goal.availableOn(d)
                      ? null
                      : Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 12,
                    color: snapshot.isCompleted(habitId, d)
                        ? Colors.white
                        : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weekdayLabels[d.weekday - 1].substring(0, 1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }
}

class _WeeksStrip extends StatelessWidget {
  const _WeeksStrip({
    required this.snapshot,
    required this.habitId,
    required this.target,
    required this.today,
    required this.color,
  });

  final HabitSnapshot snapshot;
  final int habitId;
  final int target;
  final DateTime today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final current = weekStart(today);
    final weeks = [for (var i = 7; i >= 0; i--) addDays(current, -7 * i)];
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final w in weeks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '${w.day.toString().padLeft(2, '0')}/'
                    '${w.month.toString().padLeft(2, '0')}',
                    style: textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (snapshot.weekCount(habitId, w) / target).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 8,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${snapshot.weekCount(habitId, w)}/$target',
                    textAlign: TextAlign.end,
                    style: textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
