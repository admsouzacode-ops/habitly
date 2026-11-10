import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/widgets/day_note_sheet.dart';
import 'package:habitly/widgets/empty_state.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _focused = today;
    _selected = today;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(habitSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar: $e')),
        data: (snapshot) => _buildBody(context, snapshot),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HabitSnapshot snapshot) {
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final presence = snapshot.toPresence();
    // Agendados no dia + qualquer hábito que tenha nota nesse dia.
    final dueToday = snapshot.habits
        .where(
          (h) =>
              snapshot.habitsScheduledOn(_selected).any((d) => d.id == h.id) ||
              snapshot.noteFor(h.id, _selected) != null,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        TableCalendar<void>(
          locale: 'pt_BR',
          firstDay: DateTime(today.year - 3, 1, 1),
          lastDay: DateTime(today.year + 1, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (day) => isSameDay(day, _selected),
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextFormatter: (date, locale) {
              final label = monthYearFormat.format(date);
              return label[0].toUpperCase() + label.substring(1);
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: scheme.onPrimaryContainer),
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(color: scheme.onPrimary),
            markersAlignment: Alignment.bottomCenter,
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) => _dayCell(
              context,
              snapshot,
              day,
              selected: false,
              isToday: false,
            ),
            todayBuilder: (context, day, focused) => _dayCell(
              context,
              snapshot,
              day,
              selected: false,
              isToday: true,
            ),
            selectedBuilder: (context, day, focused) => _dayCell(
              context,
              snapshot,
              day,
              selected: true,
              isToday: isSameDay(day, today),
            ),
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selected = dateOnly(selected);
              _focused = focused;
            });
          },
          onPageChanged: (focused) => setState(() => _focused = focused),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Em ${shortDateFormat.format(_selected)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (snapshot.habits.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Histórico vazio',
              message:
                  'Crie um hábito na aba Hoje para acompanhar seus dias aqui.',
            ),
          )
        else if (dueToday.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhum hábito estava agendado neste dia.'),
          )
        else
          ...dueToday.map((habit) {
            final done = snapshot.isCompleted(habit.id, _selected);
            final note = snapshot.noteFor(habit.id, _selected);
            final canNote = !_selected.isAfter(today);
            return ListTile(
              key: ValueKey('history-habit-${habit.id}'),
              onTap: canNote
                  ? () => showDayNoteSheet(
                      context,
                      habit: habit,
                      day: _selected,
                      existing: note,
                    )
                  : null,
              subtitle: note != null
                  ? NotePreview(note: note, maxLines: 3)
                  : canNote && !done
                  ? Text(
                      'Toque para anotar por que não deu',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                    )
                  : null,
              leading: CircleAvatar(
                backgroundColor: Color(
                  habit.colorValue,
                ).withValues(alpha: 0.15),
                child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(habit.name),
              trailing: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done
                    ? Color(habit.colorValue)
                    : Theme.of(context).disabledColor,
              ),
            );
          }),
        if (presence.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _legend(dayCompletion(habits: presence, day: _selected)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  String _legend(CompletionRate rate) {
    if (rate.scheduled == 0) return 'Sem hábitos agendados neste dia.';
    return '${rate.completed} de ${rate.scheduled} hábitos concluídos neste dia.';
  }

  Widget _dayCell(
    BuildContext context,
    HabitSnapshot snapshot,
    DateTime day, {
    required bool selected,
    required bool isToday,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final rate = dayCompletion(habits: snapshot.toPresence(), day: day);
    Color? fill;
    Color text = scheme.onSurface;
    if (selected) {
      fill = scheme.primary;
      text = scheme.onPrimary;
    } else if (rate.scheduled > 0 && rate.completed == rate.scheduled) {
      fill = scheme.primary.withValues(alpha: 0.22);
    } else if (rate.completed > 0) {
      fill = scheme.tertiary.withValues(alpha: 0.22);
    } else if (isToday) {
      fill = scheme.primaryContainer;
      text = scheme.onPrimaryContainer;
    }

    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: isToday && !selected
              ? Border.all(color: scheme.primary)
              : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: text,
                fontWeight: selected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            if (snapshot.hasNotesOn(day))
              Positioned(
                bottom: -9,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: selected ? scheme.onPrimary : scheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
