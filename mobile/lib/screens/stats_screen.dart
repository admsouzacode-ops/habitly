import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/logic/note_reasons.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/widgets/empty_state.dart';

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
    final month = completionRate(
      habits: presence,
      today: today,
      windowDays: 30,
    );

    if (snapshot.habits.isEmpty) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'Sem dados por enquanto',
        message:
            'As estatísticas aparecem depois que você cria hábitos e marca conclusões.',
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
        _ReasonsSection(snapshot: snapshot),
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
      habits: [HabitPresence(weekdays: weekdays, completedDays: days)],
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

class _ReasonsSection extends StatefulWidget {
  const _ReasonsSection({required this.snapshot});

  final HabitSnapshot snapshot;

  @override
  State<_ReasonsSection> createState() => _ReasonsSectionState();
}

class _ReasonsSectionState extends State<_ReasonsSection> {
  int? _habitId;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    if (_habitId != null && !snapshot.habits.any((h) => h.id == _habitId)) {
      _habitId = null;
    }
    final summary = summarizeReasons(snapshot.noteEntries(), habitId: _habitId);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final max = summary.counts.isEmpty ? 1 : summary.counts.first.count;

    return Column(
      key: const ValueKey('reasons-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Motivos mais comuns', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _habitId == null,
                onSelected: (_) => setState(() => _habitId = null),
              ),
              for (final h in snapshot.habits) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${h.icon} ${h.name}'),
                  selected: _habitId == h.id,
                  onSelected: (_) => setState(() => _habitId = h.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: summary.isEmpty
                ? Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined, color: scheme.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhuma nota ainda. Quando não conseguir cumprir um '
                          'hábito, toque no ícone de nota para registrar o motivo.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final rc in summary.counts) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${rc.reason.emoji} ${rc.reason.label}',
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: rc.count / max,
                                  minHeight: 10,
                                  color: scheme.primary,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${rc.count}',
                                textAlign: TextAlign.end,
                                style: textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        _footer(summary),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _footer(ReasonSummary s) {
    final total = s.totalNotes == 1 ? '1 nota' : '${s.totalNotes} notas';
    if (s.uncategorized == 0) return total;
    final sem = s.uncategorized == 1
        ? '1 sem motivo'
        : '${s.uncategorized} sem motivo';
    return '$total · $sem';
  }
}
