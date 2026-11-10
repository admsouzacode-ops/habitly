import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';

/// Semana ISO: 1 = segunda ... 7 = domingo (igual a [DateTime.weekday]).
bool isScheduledOn(Set<int> weekdays, DateTime day) =>
    weekdays.contains(dateOnly(day).weekday);

/// Sequência atual: dias agendados consecutivos concluídos, de trás para
/// frente a partir de [today]. Se hoje está agendado e ainda não foi
/// concluído, a contagem começa em ontem (a sequência não quebra no dia
/// corrente em andamento).
int currentStreak({
  required Set<int> weekdays,
  required Set<DateTime> completedDays,
  required DateTime today,
}) {
  if (weekdays.isEmpty) return 0;
  final done = completedDays.map(dateOnly).toSet();
  var cursor = dateOnly(today);
  if (isScheduledOn(weekdays, cursor) && !done.contains(cursor)) {
    cursor = addDays(cursor, -1);
  }

  var streak = 0;
  if (done.isEmpty) return 0;
  final limit = done.reduce((a, b) => a.isBefore(b) ? a : b);
  while (!cursor.isBefore(limit)) {
    if (isScheduledOn(weekdays, cursor)) {
      if (done.contains(cursor)) {
        streak++;
      } else {
        break;
      }
    }
    cursor = addDays(cursor, -1);
  }
  return streak;
}

/// Maior sequência já alcançada até [today] (inclusive).
int recordStreak({
  required Set<int> weekdays,
  required Set<DateTime> completedDays,
  required DateTime today,
}) {
  if (weekdays.isEmpty) return 0;
  final done = completedDays.map(dateOnly).toSet();
  final last = dateOnly(today);
  final scheduledDone =
      done.where((d) => !d.isAfter(last) && isScheduledOn(weekdays, d)).toList()
        ..sort();
  if (scheduledDone.isEmpty) return 0;

  var best = 0;
  var run = 0;
  var cursor = scheduledDone.first;
  while (!cursor.isAfter(last)) {
    if (isScheduledOn(weekdays, cursor)) {
      if (done.contains(cursor)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    cursor = addDays(cursor, 1);
  }
  return best;
}

class HabitPresence {
  const HabitPresence({
    required this.weekdays,
    required this.completedDays,
    this.weeklyTarget,
  });

  final Set<int> weekdays;
  final Set<DateTime> completedDays;

  /// Não nulo = hábito "X vezes por semana". Nas métricas por dia ele só
  /// conta nos dias em que foi feito (nunca gera falta num dia específico);
  /// nas taxas por janela conta por semana.
  final int? weeklyTarget;

  bool get isWeekly => weeklyTarget != null;

  bool scheduledOn(DateTime day) =>
      isWeekly ? completedOn(day) : isScheduledOn(weekdays, day);

  bool completedOn(DateTime day) =>
      completedDays.map(dateOnly).contains(dateOnly(day));
}

/// Um dia "completo" no app: há pelo menos um hábito agendado e todos
/// os agendados naquele dia foram concluídos. Dias sem hábitos agendados
/// são ignorados na sequência.
int overallCurrentStreak({
  required List<HabitPresence> habits,
  required DateTime today,
}) {
  if (habits.isEmpty) return 0;
  var cursor = dateOnly(today);
  if (!_isDayComplete(habits, cursor) && _hasScheduled(habits, cursor)) {
    cursor = addDays(cursor, -1);
  }

  var streak = 0;
  final limit = dateOnly(today).subtract(const Duration(days: 365 * 20));
  while (!cursor.isBefore(limit)) {
    if (_hasScheduled(habits, cursor)) {
      if (_isDayComplete(habits, cursor)) {
        streak++;
      } else {
        break;
      }
    }
    cursor = addDays(cursor, -1);
  }
  return streak;
}

int overallRecordStreak({
  required List<HabitPresence> habits,
  required DateTime today,
}) {
  if (habits.isEmpty) return 0;
  final last = dateOnly(today);
  DateTime? first;
  for (final habit in habits) {
    for (final day in habit.completedDays) {
      final d = dateOnly(day);
      if (d.isAfter(last)) continue;
      if (first == null || d.isBefore(first)) first = d;
    }
  }
  if (first == null) return 0;

  var best = 0;
  var run = 0;
  var cursor = first;
  while (!cursor.isAfter(last)) {
    if (_hasScheduled(habits, cursor)) {
      if (_isDayComplete(habits, cursor)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    cursor = addDays(cursor, 1);
  }
  return best;
}

class CompletionRate {
  const CompletionRate({required this.completed, required this.scheduled});

  final int completed;
  final int scheduled;

  double get value => scheduled == 0 ? 0 : completed / scheduled;

  int get percent => (value * 100).round();
}

/// Taxa de conclusão na janela inclusiva de [windowDays] dias terminando
/// em [today] (ex.: 7 ou 30). Numerador/denominador = ocorrências
/// hábito×dia agendadas, não dias corridos.
CompletionRate completionRate({
  required List<HabitPresence> habits,
  required DateTime today,
  required int windowDays,
}) {
  assert(windowDays > 0);
  final end = dateOnly(today);
  final start = addDays(end, -(windowDays - 1));
  var scheduled = 0;
  var completed = 0;
  final daily = habits.where((h) => !h.isWeekly).toList();
  if (windowDays == 1) {
    daily.addAll(habits.where((h) => h.isWeekly));
  } else {
    for (final habit in habits.where((h) => h.isWeekly)) {
      final rate = _weeklyWindowRate(habit, start, end);
      scheduled += rate.scheduled;
      completed += rate.completed;
    }
  }
  var cursor = start;
  while (!cursor.isAfter(end)) {
    for (final habit in daily) {
      if (!habit.scheduledOn(cursor)) continue;
      scheduled++;
      if (habit.completedOn(cursor)) completed++;
    }
    cursor = addDays(cursor, 1);
  }
  return CompletionRate(completed: completed, scheduled: scheduled);
}

/// Hábitos concluídos / agendados em um único dia.
CompletionRate dayCompletion({
  required List<HabitPresence> habits,
  required DateTime day,
}) => completionRate(habits: habits, today: dateOnly(day), windowDays: 1);

bool _hasScheduled(List<HabitPresence> habits, DateTime day) =>
    habits.any((h) => h.scheduledOn(day));

bool _isDayComplete(List<HabitPresence> habits, DateTime day) {
  final due = habits.where((h) => h.scheduledOn(day)).toList();
  if (due.isEmpty) return false;
  return due.every((h) => h.completedOn(day));
}

/// Taxa de um hábito semanal em [start]..[end]: cada semana ISO tocada pela
/// janela vale `meta` ocorrências; conclusões acima da meta não contam. A
/// semana em andamento (que contém [end]) só conta o que já foi feito, para
/// não penalizar uma semana que ainda pode ser cumprida.
CompletionRate _weeklyWindowRate(
  HabitPresence habit,
  DateTime start,
  DateTime end,
) {
  final target = habit.weeklyTarget!.clamp(1, 7);
  final done = habit.completedDays
      .map(dateOnly)
      .where((d) => !d.isBefore(start) && !d.isAfter(end))
      .toList();
  var scheduled = 0;
  var completed = 0;
  var week = weekStart(start);
  final currentWeek = weekStart(end);
  while (!week.isAfter(currentWeek)) {
    final weekEnd = addDays(week, 6);
    final count = done
        .where((d) => !d.isBefore(week) && !d.isAfter(weekEnd))
        .length;
    final capped = count > target ? target : count;
    if (week == currentWeek && capped < target) {
      scheduled += capped;
    } else {
      scheduled += target;
    }
    completed += capped;
    week = addDays(week, 7);
  }
  return CompletionRate(completed: completed, scheduled: scheduled);
}

// ---------------------------------------------------------------------------
// Sequências por tipo de meta (app 1.0.0+7)
// ---------------------------------------------------------------------------

enum StreakUnit { days, weeks }

class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.unit,
  });

  final int current;
  final int best;
  final StreakUnit unit;

  String label(int value) => switch (unit) {
    StreakUnit.days => value == 1 ? 'dia' : 'dias',
    StreakUnit.weeks => value == 1 ? 'semana' : 'semanas',
  };

  /// Ex.: "🔥 5 dias seguidos" / "🔥 2 semanas seguidas".
  String get currentText {
    final suffix = unit == StreakUnit.days
        ? (current == 1 ? 'seguido' : 'seguidos')
        : (current == 1 ? 'seguida' : 'seguidas');
    return '🔥 $current ${label(current)} $suffix';
  }
}

/// Sequência semanal atual: semanas ISO consecutivas com pelo menos
/// [target] conclusões. A semana corrente só entra quando a meta já foi
/// batida; enquanto não foi, a contagem parte da semana anterior (a semana
/// em andamento não quebra a sequência).
int weeklyCurrentStreak({
  required int target,
  required Set<DateTime> completedDays,
  required DateTime today,
}) {
  final goal = target.clamp(1, 7);
  final done = completedDays
      .map(dateOnly)
      .where((d) => !d.isAfter(dateOnly(today)))
      .toSet();
  if (done.isEmpty) return 0;
  var week = weekStart(today);
  if (completionsInWeekOf(done, week) < goal) week = addDays(week, -7);
  final earliest = done.reduce((a, b) => a.isBefore(b) ? a : b);
  var streak = 0;
  while (!week.isBefore(weekStart(earliest)) &&
      completionsInWeekOf(done, week) >= goal) {
    streak++;
    week = addDays(week, -7);
  }
  return streak;
}

/// Maior sequência de semanas consecutivas com a meta batida até [today].
int weeklyRecordStreak({
  required int target,
  required Set<DateTime> completedDays,
  required DateTime today,
}) {
  final goal = target.clamp(1, 7);
  final done = completedDays
      .map(dateOnly)
      .where((d) => !d.isAfter(dateOnly(today)))
      .toSet();
  if (done.isEmpty) return 0;
  final earliest = done.reduce((a, b) => a.isBefore(b) ? a : b);
  var week = weekStart(earliest);
  final last = weekStart(today);
  var best = 0;
  var run = 0;
  while (!week.isAfter(last)) {
    if (completionsInWeekOf(done, week) >= goal) {
      run++;
      if (run > best) best = run;
    } else if (week != last) {
      run = 0;
    }
    week = addDays(week, 7);
  }
  return best;
}

int completionsInWeekOf(Set<DateTime> done, DateTime monday) {
  final end = addDays(monday, 6);
  return done.where((d) => !d.isBefore(monday) && !d.isAfter(end)).length;
}

/// Sequência atual e recorde conforme o tipo de meta. Diária e quantidade
/// contam dias agendados (dias fora da agenda não quebram); semanal conta
/// semanas com a meta batida.
StreakInfo streakFor({
  required HabitGoal goal,
  required Set<DateTime> completedDays,
  required DateTime today,
}) {
  if (goal.isWeekly) {
    return StreakInfo(
      current: weeklyCurrentStreak(
        target: goal.safeWeeklyTarget,
        completedDays: completedDays,
        today: today,
      ),
      best: weeklyRecordStreak(
        target: goal.safeWeeklyTarget,
        completedDays: completedDays,
        today: today,
      ),
      unit: StreakUnit.weeks,
    );
  }
  return StreakInfo(
    current: currentStreak(
      weekdays: goal.weekdays,
      completedDays: completedDays,
      today: today,
    ),
    best: recordStreak(
      weekdays: goal.weekdays,
      completedDays: completedDays,
      today: today,
    ),
    unit: StreakUnit.days,
  );
}
