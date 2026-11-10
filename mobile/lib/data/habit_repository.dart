import 'package:drift/drift.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';
import 'package:habitly/logic/note_reasons.dart';

Set<int> parseWeekdays(String raw) {
  if (raw.trim().isEmpty) return {};
  return raw
      .split(',')
      .map((p) => int.tryParse(p.trim()))
      .whereType<int>()
      .where((d) => d >= 1 && d <= 7)
      .toSet();
}

String encodeWeekdays(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.join(',');
}

class HabitSnapshot {
  const HabitSnapshot({
    required this.habits,
    required this.completions,
    this.notes = const [],
  });

  final List<Habit> habits;
  final List<Completion> completions;
  final List<HabitDayNote> notes;

  HabitDayNote? noteFor(int habitId, DateTime day) {
    final key = dateKey(day);
    for (final n in notes) {
      if (n.habitId == habitId && n.day == key) return n;
    }
    return null;
  }

  bool hasNotesOn(DateTime day) {
    final key = dateKey(day);
    return notes.any((n) => n.day == key);
  }

  List<NoteEntry> noteEntries() => [
    for (final n in notes) NoteEntry(habitId: n.habitId, reasonCode: n.reason),
  ];

  Set<DateTime> completedDaysFor(int habitId) => dateKeysToDates(
    completions.where((c) => c.habitId == habitId).map((c) => c.day),
  );

  bool isCompleted(int habitId, DateTime day) =>
      completions.any((c) => c.habitId == habitId && c.day == dateKey(day));

  List<Habit> habitsScheduledOn(DateTime day) => habits
      .where((h) => isScheduledOn(parseWeekdays(h.weekdays), day))
      .toList();

  List<HabitPresence> toPresence() => [
    for (final habit in habits)
      HabitPresence(
        weekdays: parseWeekdays(habit.weekdays),
        completedDays: completedDaysFor(habit.id),
      ),
  ];
}

class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Stream<List<Habit>> watchHabits() => _db.watchHabits();

  Stream<HabitSnapshot> watchSnapshot() async* {
    yield await loadSnapshot();
    yield* _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.habits,
            _db.completions,
            _db.habitDayNotes,
          ]),
        )
        .asyncMap((_) => loadSnapshot());
  }

  Future<HabitSnapshot> loadSnapshot() async {
    return HabitSnapshot(
      habits: await _db.getHabits(),
      completions: await _db.allCompletions(),
      notes: await _db.allNotes(),
    );
  }

  Future<int> habitCount() => _db.habitCount();

  Future<int> addHabit({
    required String name,
    required String icon,
    required int colorValue,
    required Set<int> weekdays,
    String? reminder,
  }) {
    return _db.insertHabit(
      HabitsCompanion.insert(
        name: name.trim(),
        icon: Value(icon),
        colorValue: Value(colorValue),
        weekdays: Value(encodeWeekdays(weekdays)),
        reminder: Value(reminder),
      ),
    );
  }

  Future<void> updateHabit({
    required int id,
    required String name,
    required String icon,
    required int colorValue,
    required Set<int> weekdays,
    String? reminder,
  }) {
    return _db.updateHabitRow(
      id,
      HabitsCompanion(
        name: Value(name.trim()),
        icon: Value(icon),
        colorValue: Value(colorValue),
        weekdays: Value(encodeWeekdays(weekdays)),
        reminder: Value(reminder),
      ),
    );
  }

  Future<void> deleteHabit(int id) => _db.deleteHabitById(id);

  Future<void> setCompleted({
    required int habitId,
    required DateTime day,
    required bool completed,
  }) {
    return _db.setCompleted(
      habitId: habitId,
      day: dateKey(day),
      completed: completed,
    );
  }

  Future<HabitDayNote?> noteFor({
    required int habitId,
    required DateTime day,
  }) => _db.noteFor(habitId, dateKey(day));

  /// Salva a nota do dia. Texto e motivo vazios ao mesmo tempo apagam a nota.
  Future<void> saveNote({
    required int habitId,
    required DateTime day,
    required String note,
    NoteReason? reason,
  }) async {
    var text = note.trim();
    if (text.length > maxNoteLength) text = text.substring(0, maxNoteLength);
    if (text.isEmpty && reason == null) {
      await deleteNote(habitId: habitId, day: day);
      return;
    }
    await _db.upsertNote(
      habitId: habitId,
      day: dateKey(day),
      note: text,
      reason: reason?.code,
    );
  }

  Future<void> deleteNote({required int habitId, required DateTime day}) =>
      _db.deleteNote(habitId, dateKey(day));
}
