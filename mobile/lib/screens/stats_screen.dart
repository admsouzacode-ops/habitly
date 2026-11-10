import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/providers/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar: $e')),
        data: (snapshot) => _StatsBody(snapshot: snapshot),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.snapshot});

  final HabitSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final presence = snapshot.toPresence();
    final current = overallCurrentStreak(habits: presence, today: today);
    final record = overallRecordStreak(habits: presence, today: today);
    final week = completionRate(habits: presence, today: today, windowDays: 7);
    final month = completionRate(habits: presence, today: today, windowDays: 30);

    if (snapshot.habits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'As estatísticas aparecem depois que você cria hábitos e marca conclusões.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Visão geral', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Sequência atual',
                value: '$current',
                hint: current == 1 ? 'dia consecutivo' : 'dias consecutivos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Recorde',
                value: '$record',
                hint: record == 1 ? 'dia' : 'dias',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.date_range_outlined,
                label: 'Taxa em 7 dias',
                value: '${week.percent}%',
                hint: '${week.completed} de ${week.scheduled} concluídos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                label: 'Taxa em 30 dias',
                value: '${month.percent}%',
                hint: '${month.completed} de ${month.scheduled} concluídos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Por hábito', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final habit in snapshot.habits)
          _HabitStatTile(snapshot: snapshot, habitId: habit.id, today: today),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _HabitStatTile extends StatelessWidget {
  const _HabitStatTile({
    required this.snapshot,
    required this.habitId,
    required this.today,
  });

  final HabitSnapshot snapshot;
  final int habitId;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final habit = snapshot.habits.firstWhere((h) => h.id == habitId);
    final weekdays = parseWeekdays(habit.weekdays);
    final days = snapshot.completedDaysFor(habit.id);
    final current = currentStreak(
      weekdays: weekdays,
      completedDays: days,
      today: today,
    );
    final record = recordStreak(
      weekdays: weekdays,
      completedDays: days,
      today: today,
    );
    final week = completionRate(
      habits: [
        HabitPresence(weekdays: weekdays, completedDays: days),
      ],
      today: today,
      windowDays: 7,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(habit.colorValue).withValues(alpha: 0.15),
          child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(habit.name),
        subtitle: Text(
          'Sequência $current · recorde $record · 7 dias ${week.percent}%',
        ),
      ),
    );
  }
}
