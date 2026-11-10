import 'package:drift/drift.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';

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
  const HabitSnapshot({required this.habits, required this.completions});

  final List<Habit> habits;
  final List<Completion> completions;

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
          TableUpdateQuery.onAllTables([_db.habits, _db.completions]),
        )
        .asyncMap((_) => loadSnapshot());
  }

  Future<HabitSnapshot> loadSnapshot() async {
    return HabitSnapshot(
      habits: await _db.getHabits(),
      completions: await _db.allCompletions(),
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
}
