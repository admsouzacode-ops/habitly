import 'package:habitly/logic/dates.dart';

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
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var streak = 0;
  final limit = dateOnly(today).subtract(const Duration(days: 365 * 20));
  while (!cursor.isBefore(limit)) {
    if (isScheduledOn(weekdays, cursor)) {
      if (done.contains(cursor)) {
        streak++;
      } else {
        break;
      }
    }
    cursor = cursor.subtract(const Duration(days: 1));
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
  final scheduledDone = done.where((d) => !d.isAfter(last) && isScheduledOn(weekdays, d)).toList()
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
    cursor = cursor.add(const Duration(days: 1));
  }
  return best;
}

class HabitPresence {
  const HabitPresence({
    required this.weekdays,
    required this.completedDays,
  });

  final Set<int> weekdays;
  final Set<DateTime> completedDays;

  bool scheduledOn(DateTime day) => isScheduledOn(weekdays, day);

  bool completedOn(DateTime day) => completedDays.map(dateOnly).contains(dateOnly(day));
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
    cursor = cursor.subtract(const Duration(days: 1));
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
    cursor = cursor.subtract(const Duration(days: 1));
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
    cursor = cursor.add(const Duration(days: 1));
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
  final start = end.subtract(Duration(days: windowDays - 1));
  var scheduled = 0;
  var completed = 0;
  var cursor = start;
  while (!cursor.isAfter(end)) {
    for (final habit in habits) {
      if (!habit.scheduledOn(cursor)) continue;
      scheduled++;
      if (habit.completedOn(cursor)) completed++;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return CompletionRate(completed: completed, scheduled: scheduled);
}

/// Hábitos concluídos / agendados em um único dia.
CompletionRate dayCompletion({
  required List<HabitPresence> habits,
  required DateTime day,
}) =>
    completionRate(habits: habits, today: dateOnly(day), windowDays: 1);

bool _hasScheduled(List<HabitPresence> habits, DateTime day) =>
    habits.any((h) => h.scheduledOn(day));

bool _isDayComplete(List<HabitPresence> habits, DateTime day) {
  final due = habits.where((h) => h.scheduledOn(day)).toList();
  if (due.isEmpty) return false;
  return due.every((h) => h.completedOn(day));
}
