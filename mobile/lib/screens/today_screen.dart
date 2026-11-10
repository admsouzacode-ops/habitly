import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/habit_detail_screen.dart';
import 'package:habitly/screens/habit_form_screen.dart';
import 'package:habitly/screens/settings_screen.dart';
import 'package:habitly/widgets/day_note_sheet.dart';
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

    final due = snapshot.habitsDueOn(today);
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
    final goal = snapshot.goalFor(habit);
    final done = snapshot.isCompleted(habit.id, today);
    final streak = snapshot.streakOf(habit, today);
    final color = Color(habit.colorValue);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remindersOn = ref.watch(remindersEnabledProvider);
    final note = snapshot.noteFor(habit.id, today);
    final repo = ref.read(habitRepositoryProvider);
    void openNote() =>
        showDayNoteSheet(context, habit: habit, day: today, existing: note);

    final weekCount = snapshot.weekCount(habit.id, today);
    final amount = snapshot.amountFor(habit.id, today);
    final weekMet = goal.isWeekly && weekCount >= goal.safeWeeklyTarget;
    final streakText = streak.current > 0 ? streak.currentText : null;

    final String status;
    switch (goal.type) {
      case GoalType.weekly:
        final base = weekMet
            ? '✅ $weekCount/${goal.safeWeeklyTarget} esta semana'
            : '$weekCount/${goal.safeWeeklyTarget} esta semana';
        status = streakText == null ? base : '$base · $streakText';
      case GoalType.quantity:
        final unit = goal.quantityUnit.trim();
        final base =
            '${formatAmount(amount)}/${formatAmount(goal.safeQuantityTarget)}'
            '${unit.isEmpty ? '' : ' $unit'}';
        status = !scheduledToday
            ? 'Não agendado para hoje'
            : streakText == null
            ? base
            : '$base · $streakText';
      case GoalType.daily:
        if (!scheduledToday) {
          status = 'Não agendado para hoje';
        } else if (streakText == null) {
          status = done ? 'Feito hoje' : 'Comece a sequência hoje';
        } else {
          status = streakText;
        }
    }
    final struck = goal.isWeekly ? weekMet : done;

    return Card(
      key: ValueKey('habit-card-${habit.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: openNote,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HabitDetailScreen(habitId: habit.id),
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
                          decoration: struck
                              ? TextDecoration.lineThrough
                              : null,
                          color: struck ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            status,
                            key: ValueKey('habit-status-${habit.id}'),
                            style: textTheme.bodySmall,
                          ),
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
                      if (goal.isQuantity && scheduledToday) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (amount / goal.safeQuantityTarget).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 6,
                            color: color,
                            backgroundColor: color.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                      if (goal.isWeekly) ...[
                        const SizedBox(height: 6),
                        _WeekDots(
                          count: weekCount,
                          target: goal.safeWeeklyTarget,
                          color: color,
                        ),
                      ],
                      if (note != null) ...[
                        const SizedBox(height: 4),
                        NotePreview(note: note),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('habit-note-${habit.id}'),
                tooltip: note != null
                    ? 'Editar nota do dia'
                    : 'Por que não consegui?',
                onPressed: openNote,
                icon: Icon(
                  note != null ? Icons.sticky_note_2 : Icons.edit_note_outlined,
                  color: note != null ? scheme.tertiary : scheme.outline,
                ),
              ),
              if (goal.isQuantity && scheduledToday)
                _QuantityControls(
                  habit: habit,
                  goal: goal,
                  amount: amount,
                  done: done,
                  color: color,
                  onChanged: (value) =>
                      repo.setAmount(habit: habit, day: today, amount: value),
                )
              else if (scheduledToday || goal.isWeekly)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CheckButton(
                    done: done,
                    color: color,
                    onChanged: (value) {
                      repo.setCompleted(
                        habitId: habit.id,
                        day: today,
                        completed: value,
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 4),
                  child: Icon(Icons.event_busy_outlined, color: scheme.outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({
    required this.count,
    required this.target,
    required this.color,
  });

  final int count;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < target; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? color : color.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.habit,
    required this.goal,
    required this.amount,
    required this.done,
    required this.color,
    required this.onChanged,
  });

  final Habit habit;
  final HabitGoal goal;
  final double amount;
  final bool done;
  final Color color;
  final ValueChanged<double> onChanged;

  Future<void> _input(BuildContext context) async {
    final value = await showQuantityInputDialog(
      context,
      habit: habit,
      goal: goal,
      current: amount,
    );
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final step = goal.safeQuantityStep;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('habit-minus-${habit.id}'),
            tooltip: 'Diminuir ${formatAmount(step)}',
            visualDensity: VisualDensity.compact,
            onPressed: amount <= 0 ? null : () => onChanged(amount - step),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          InkWell(
            key: ValueKey('habit-amount-${habit.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => _input(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: done
                  ? Icon(Icons.check_circle, color: color, size: 26)
                  : Text(
                      formatAmount(amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
            ),
          ),
          IconButton(
            key: ValueKey('habit-plus-${habit.id}'),
            tooltip: 'Somar ${formatAmount(step)}',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(amount + step),
            icon: Icon(Icons.add_circle, color: color),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para digitar o valor do dia (ex.: 1,5 litro).
Future<double?> showQuantityInputDialog(
  BuildContext context, {
  required Habit habit,
  required HabitGoal goal,
  required double current,
}) {
  final controller = TextEditingController(
    text: current > 0 ? formatAmount(current) : '',
  );
  final unit = goal.quantityUnit.trim();
  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${habit.icon} ${habit.name}'),
      content: TextField(
        key: const ValueKey('quantity-input'),
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Quanto hoje?',
          suffixText: unit.isEmpty ? null : unit,
          helperText:
              'Meta: ${formatAmount(goal.safeQuantityTarget)}'
              '${unit.isEmpty ? '' : ' $unit'}',
        ),
        onSubmitted: (raw) => Navigator.pop(context, parseAmount(raw)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, parseAmount(controller.text)),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
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
