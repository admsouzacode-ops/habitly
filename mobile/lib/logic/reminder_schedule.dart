import 'package:timezone/timezone.dart' as tz;

/// Horário de lembrete no formato HH:mm.
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  static ReminderTime? tryParse(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return null;
    return ReminderTime(h, m);
  }

  String encode() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// ID estável da notificação de um hábito em um dia da semana ISO (1..7).
int reminderNotificationId(int habitId, int weekday) => habitId * 10 + weekday;

/// Próxima ocorrência (estritamente depois de [now]) do [weekday] ISO no
/// horário [time], no fuso de [now].
tz.TZDateTime nextWeeklyOccurrence({
  required tz.TZDateTime now,
  required int weekday,
  required ReminderTime time,
}) {
  var candidate = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  var guard = 0;
  while ((candidate.weekday != weekday || !candidate.isAfter(now)) &&
      guard < 8) {
    candidate = tz.TZDateTime(
      now.location,
      candidate.year,
      candidate.month,
      candidate.day + 1,
      time.hour,
      time.minute,
    );
    guard++;
  }
  return candidate;
}

/// Um lembrete semanal planejado (um por hábito e dia da semana).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.habitId,
    required this.weekday,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final int habitId;
  final int weekday;
  final tz.TZDateTime when;
  final String title;
  final String body;
}

/// Dados mínimos de um hábito para planejar lembretes.
class ReminderHabit {
  const ReminderHabit({
    required this.id,
    required this.name,
    required this.icon,
    required this.weekdays,
    required this.reminder,
  });

  final int id;
  final String name;
  final String icon;
  final Set<int> weekdays;
  final String? reminder;
}

List<PlannedReminder> planReminders({
  required Iterable<ReminderHabit> habits,
  required tz.TZDateTime now,
  required bool enabled,
}) {
  if (!enabled) return const [];
  final result = <PlannedReminder>[];
  for (final habit in habits) {
    final time = ReminderTime.tryParse(habit.reminder);
    if (time == null) continue;
    final days = habit.weekdays.where((d) => d >= 1 && d <= 7).toList()..sort();
    for (final day in days) {
      result.add(
        PlannedReminder(
          id: reminderNotificationId(habit.id, day),
          habitId: habit.id,
          weekday: day,
          when: nextWeeklyOccurrence(now: now, weekday: day, time: time),
          title: '${habit.icon} ${habit.name}',
          body: 'Hora do seu hábito. Bora manter a sequência!',
        ),
      );
    }
  }
  return result;
}
