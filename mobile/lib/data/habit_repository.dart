import 'package:drift/drift.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
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

HabitGoal goalOf(Habit habit) {
  final type = GoalType.parse(habit.goalType);
  return HabitGoal(
    type: type,
    weekdays: type == GoalType.weekly
        ? allWeekdays
        : parseWeekdays(habit.weekdays),
    weeklyTarget: habit.weeklyTarget,
    quantityTarget: habit.quantityTarget,
    quantityUnit: habit.quantityUnit,
    quantityStep: habit.quantityStep,
  );
}

class HabitSnapshot {
  const HabitSnapshot({
    required this.habits,
    required this.completions,
    this.notes = const [],
    this.amounts = const [],
  });

  final List<Habit> habits;
  final List<Completion> completions;
  final List<HabitDayNote> notes;
  final List<HabitAmount> amounts;

  HabitGoal goalFor(Habit habit) => goalOf(habit);

  /// Valor registrado no dia (metas de quantidade). 0 quando não há registro.
  double amountFor(int habitId, DateTime day) {
    final key = dateKey(day);
    for (final a in amounts) {
      if (a.habitId == habitId && a.day == key) return a.amount;
    }
    return 0;
  }

  /// Conclusões na semana ISO de [day] (metas semanais).
  int weekCount(int habitId, DateTime day) =>
      completionsInWeek(completedDaysFor(habitId), day);

  /// Hábito aparece em "Para hoje": diário/quantidade nos dias agendados;
  /// semanal enquanto a meta da semana não foi batida ou se já foi feito hoje.
  bool isDueOn(Habit habit, DateTime day) {
    final goal = goalOf(habit);
    if (!goal.isWeekly) return goal.availableOn(day);
    return isCompleted(habit.id, day) ||
        weekCount(habit.id, day) < goal.safeWeeklyTarget;
  }

  List<Habit> habitsDueOn(DateTime day) =>
      habits.where((h) => isDueOn(h, day)).toList();

  bool weeklyGoalMet(Habit habit, DateTime day) {
    final goal = goalOf(habit);
    return goal.isWeekly && weekCount(habit.id, day) >= goal.safeWeeklyTarget;
  }

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

  /// Agendados no dia (histórico): diário/quantidade pelos dias da semana;
  /// semanal apenas nos dias em que foi feito (não existe "falta" diária).
  List<Habit> habitsScheduledOn(DateTime day) => habits.where((h) {
    final goal = goalOf(h);
    if (goal.isWeekly) return isCompleted(h.id, day);
    return isScheduledOn(goal.weekdays, day);
  }).toList();

  HabitPresence presenceOf(Habit habit) {
    final goal = goalOf(habit);
    return HabitPresence(
      weekdays: goal.weekdays,
      completedDays: completedDaysFor(habit.id),
      weeklyTarget: goal.isWeekly ? goal.safeWeeklyTarget : null,
    );
  }

  List<HabitPresence> toPresence() => [
    for (final habit in habits) presenceOf(habit),
  ];

  StreakInfo streakOf(Habit habit, DateTime today) => streakFor(
    goal: goalOf(habit),
    completedDays: completedDaysFor(habit.id),
    today: today,
  );
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
            _db.habitAmounts,
          ]),
        )
        .asyncMap((_) => loadSnapshot());
  }

  Future<HabitSnapshot> loadSnapshot() async {
    return HabitSnapshot(
      habits: await _db.getHabits(),
      completions: await _db.allCompletions(),
      notes: await _db.allNotes(),
      amounts: await _db.allAmounts(),
    );
  }

  Future<int> habitCount() => _db.habitCount();

  Future<int> addHabit({
    required String name,
    required String icon,
    required int colorValue,
    required Set<int> weekdays,
    String? reminder,
    HabitGoal? goal,
  }) {
    final g = goal ?? HabitGoal(weekdays: weekdays);
    return _db.insertHabit(
      HabitsCompanion.insert(
        name: name.trim(),
        icon: Value(icon),
        colorValue: Value(colorValue),
        weekdays: Value(encodeWeekdays(g.isWeekly ? allWeekdays : weekdays)),
        reminder: Value(reminder),
        goalType: Value(g.type.code),
        weeklyTarget: Value(g.safeWeeklyTarget),
        quantityTarget: Value(g.safeQuantityTarget),
        quantityUnit: Value(g.quantityUnit.trim()),
        quantityStep: Value(g.safeQuantityStep),
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
    HabitGoal? goal,
  }) async {
    final g = goal ?? HabitGoal(weekdays: weekdays);
    await _db.updateHabitRow(
      id,
      HabitsCompanion(
        name: Value(name.trim()),
        icon: Value(icon),
        colorValue: Value(colorValue),
        weekdays: Value(encodeWeekdays(g.isWeekly ? allWeekdays : weekdays)),
        reminder: Value(reminder),
        goalType: Value(g.type.code),
        weeklyTarget: Value(g.safeWeeklyTarget),
        quantityTarget: Value(g.safeQuantityTarget),
        quantityUnit: Value(g.quantityUnit.trim()),
        quantityStep: Value(g.safeQuantityStep),
      ),
    );
    // Meta de quantidade mudou: reavalia a conclusão de hoje.
    if (g.isQuantity) {
      final today = dateKey(DateTime.now());
      final row = await _db.amountFor(id, today);
      if (row != null) {
        await _db.setAmount(
          habitId: id,
          day: today,
          amount: row.amount,
          target: g.safeQuantityTarget,
        );
      }
    }
  }

  /// Define o valor do dia de um hábito de quantidade (>= 0) e conclui o
  /// dia quando atinge a meta.
  Future<void> setAmount({
    required Habit habit,
    required DateTime day,
    required double amount,
  }) {
    final goal = goalOf(habit);
    final value = amount < 0 ? 0.0 : (amount * 100).roundToDouble() / 100;
    return _db.setAmount(
      habitId: habit.id,
      day: dateKey(day),
      amount: value,
      target: goal.safeQuantityTarget,
    );
  }

  /// Soma [delta] ao valor do dia (ex.: +1 copo, -0,5 litro).
  Future<void> addAmount({
    required Habit habit,
    required DateTime day,
    required double delta,
  }) async {
    final row = await _db.amountFor(habit.id, dateKey(day));
    await setAmount(habit: habit, day: day, amount: (row?.amount ?? 0) + delta);
  }

  /// Ação principal de um hábito (card ou widget): alterna a conclusão em
  /// diário/semanal; em quantidade soma um passo.
  Future<void> quickAction({
    required Habit habit,
    required DateTime day,
  }) async {
    final goal = goalOf(habit);
    if (goal.isQuantity) {
      await addAmount(habit: habit, day: day, delta: goal.safeQuantityStep);
      return;
    }
    final done = (await _db.completionsInRange(
      dateKey(day),
      dateKey(day),
    )).any((c) => c.habitId == habit.id);
    await setCompleted(habitId: habit.id, day: day, completed: !done);
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
