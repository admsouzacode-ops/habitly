import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/habit_form_screen.dart';
import 'package:habitly/screens/settings_screen.dart';
import 'package:habitly/widgets/empty_state.dart';
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HabitFormScreen()));
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
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewHabit(context, ref),
        tooltip: 'Adicionar hábito',
        icon: const Icon(Icons.add),
        label: const Text('Novo hábito'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar: $e')),
        data: (snapshot) => _TodayBody(
          snapshot: snapshot,
          today: today,
          onCreate: () => _openNewHabit(context, ref),
        ),
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({
    required this.snapshot,
    required this.today,
    required this.onCreate,
  });

  final HabitSnapshot snapshot;
  final DateTime today;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshot.habits.isEmpty) {
      return EmptyState(
        icon: Icons.spa_outlined,
        title: 'Nenhum hábito ainda',
        message: 'Crie o primeiro hábito e comece sua sequência hoje.',
        actionLabel: 'Criar primeiro hábito',
        onAction: onCreate,
      );
    }

    final due = snapshot.habitsScheduledOn(today);
    final others = snapshot.habits
        .where((h) => !due.any((d) => d.id == h.id))
        .toList();
    final doneCount = due
        .where((h) => snapshot.isCompleted(h.id, today))
        .length;
    final total = due.length;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _ProgressCard(done: doneCount, total: total),
        if (due.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Para hoje', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final habit in due)
            _HabitCard(snapshot: snapshot, habit: habit, today: today),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Outros dias', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final habit in others)
            _HabitCard(
              snapshot: snapshot,
              habit: habit,
              today: today,
              scheduledToday: false,
            ),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();
    final String headline;
    final String detail;
    if (total == 0) {
      headline = 'Dia livre';
      detail = 'Nenhum hábito agendado para hoje.';
    } else if (done == total) {
      headline = 'Tudo feito!';
      detail = 'Você concluiu os $total hábitos de hoje.';
    } else {
      headline = '$done de $total concluídos';
      final left = total - done;
      detail = left == 1 ? 'Falta 1 hábito.' : 'Faltam $left hábitos.';
    }

    return Card(
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      color: scheme.primary,
                      backgroundColor: scheme.surface.withValues(alpha: 0.6),
                    ),
                  ),
                  Center(
                    child: done == total && total > 0
                        ? Icon(
                            Icons.check_rounded,
                            size: 40,
                            color: scheme.primary,
                          )
                        : Text(
                            '$percent%',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  const _HabitCard({
    required this.snapshot,
    required this.habit,
    required this.today,
    this.scheduledToday = true,
  });

  final HabitSnapshot snapshot;
  final Habit habit;
  final DateTime today;
  final bool scheduledToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = snapshot.isCompleted(habit.id, today);
    final streak = currentStreak(
      weekdays: parseWeekdays(habit.weekdays),
      completedDays: snapshot.completedDaysFor(habit.id),
      today: today,
    );
    final color = Color(habit.colorValue);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remindersOn = ref.watch(remindersEnabledProvider);

    final String status;
    if (!scheduledToday) {
      status = 'Não agendado para hoje';
    } else if (streak == 0) {
      status = done ? 'Feito hoje' : 'Comece a sequência hoje';
    } else {
      status = '🔥 $streak ${streak == 1 ? 'dia' : 'dias'} seguidos';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HabitFormScreen(habit: habit),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: textTheme.titleMedium?.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(status, style: textTheme.bodySmall),
                          if (habit.reminder != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  remindersOn
                                      ? Icons.alarm
                                      : Icons.alarm_off_outlined,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  habit.reminder!,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (scheduledToday)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CheckButton(
                    done: done,
                    color: color,
                    onChanged: (value) {
                      ref
                          .read(habitRepositoryProvider)
                          .setCompleted(
                            habitId: habit.id,
                            day: today,
                            completed: value,
                          );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.event_busy_outlined, color: scheme.outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.color,
    required this.onChanged,
  });

  final bool done;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: done,
      label: done ? 'Concluído' : 'Marcar como concluído',
      child: IconButton(
        key: const ValueKey('habit-check'),
        iconSize: 30,
        onPressed: () => onChanged(!done),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: done
              ? Icon(Icons.check_circle, key: const ValueKey(1), color: color)
              : Icon(
                  Icons.radio_button_unchecked,
                  key: const ValueKey(0),
                  color: Theme.of(context).colorScheme.outline,
                ),
        ),
      ),
    );
  }
}
