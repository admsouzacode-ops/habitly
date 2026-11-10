import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/habit_form_screen.dart';
import 'package:habitly/screens/settings_screen.dart';
import 'package:habitly/widgets/upgrade_dialog.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _openNewHabit(BuildContext context, WidgetRef ref) async {
    final premium = ref.read(premiumProvider);
    final count = await ref.read(habitRepositoryProvider).habitCount();
    if (!context.mounted) return;
    if (!premium && count >= freeHabitLimit) {
      await showUpgradeDialog(context);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HabitFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitSnapshotProvider);
    final today = dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoje'),
            Text(
              capitalizedDateHeading(today),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewHabit(context, ref),
        tooltip: 'Adicionar hábito',
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar: $e')),
        data: (snapshot) => _TodayBody(snapshot: snapshot, today: today),
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({required this.snapshot, required this.today});

  final HabitSnapshot snapshot;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = snapshot.habitsScheduledOn(today);
    final others = snapshot.habits
        .where((h) => !due.any((d) => d.id == h.id))
        .toList();

    if (snapshot.habits.isEmpty) {
      return const _EmptyHabits();
    }

    final doneCount = due.where((h) => snapshot.isCompleted(h.id, today)).length;
    final total = due.length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'Nenhum hábito para hoje'
                      : '$doneCount de $total hábitos concluídos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (due.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Para hoje', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final habit in due)
            _HabitTile(
              snapshot: snapshot,
              habitId: habit.id,
              today: today,
            ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Fora do calendário de hoje',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final habit in others)
            _HabitTile(
              snapshot: snapshot,
              habitId: habit.id,
              today: today,
              scheduledToday: false,
            ),
        ],
      ],
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'Nenhum hábito ainda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Toque em + para criar o primeiro e começar sua sequência.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({
    required this.snapshot,
    required this.habitId,
    required this.today,
    this.scheduledToday = true,
  });

  final HabitSnapshot snapshot;
  final int habitId;
  final DateTime today;
  final bool scheduledToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = snapshot.habits.firstWhere((h) => h.id == habitId);
    final done = snapshot.isCompleted(habit.id, today);
    final streak = currentStreak(
      weekdays: parseWeekdays(habit.weekdays),
      completedDays: snapshot.completedDaysFor(habit.id),
      today: today,
    );
    final color = Color(habit.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HabitFormScreen(habit: habit),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(habit.name),
        subtitle: Text(
          scheduledToday
              ? (streak == 0
                  ? 'Comece a sequência hoje'
                  : 'Sequência: $streak ${streak == 1 ? 'dia' : 'dias'}')
              : 'Não está agendado para hoje',
        ),
        trailing: scheduledToday
            ? Checkbox(
                value: done,
                onChanged: (value) {
                  ref.read(habitRepositoryProvider).setCompleted(
                        habitId: habit.id,
                        day: today,
                        completed: value ?? false,
                      );
                },
              )
            : Icon(Icons.event_busy_outlined, color: Theme.of(context).hintColor),
      ),
    );
  }
}
