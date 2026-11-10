import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/logic/reminder_schedule.dart';
import 'package:habitly/services/reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class FakeBackend implements ReminderBackend {
  FakeBackend({this.exact = false, this.failExact = false});

  bool exact;
  bool failExact;
  int cancelCalls = 0;
  final scheduled = <int, (PlannedReminder, bool)>{};

  @override
  tz.Location get location => tz.getLocation('America/Sao_Paulo');

  @override
  Future<void> init() async {}

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<bool> requestExactPermission() async => exact = true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled.clear();
  }

  @override
  Future<void> scheduleWeekly(PlannedReminder r, {required bool exact}) async {
    if (exact && failExact) throw StateError('exact_alarms_not_permitted');
    scheduled[r.id] = (r, exact);
  }
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('ReminderTime', () {
    test('aceita HH:mm válido e rejeita lixo', () {
      expect(ReminderTime.tryParse('08:05'), const ReminderTime(8, 5));
      expect(ReminderTime.tryParse('7:30'), const ReminderTime(7, 30));
      expect(ReminderTime.tryParse('24:00'), isNull);
      expect(ReminderTime.tryParse('ab:cd'), isNull);
      expect(ReminderTime.tryParse(null), isNull);
      expect(const ReminderTime(7, 3).encode(), '07:03');
    });
  });

  group('nextWeeklyOccurrence', () {
    tz.Location sp() => tz.getLocation('America/Sao_Paulo');

    test('mesmo dia ainda no futuro', () {
      // 10/11/2026 é terça-feira (weekday 2).
      final now = tz.TZDateTime(sp(), 2026, 11, 10, 7, 0);
      final next = nextWeeklyOccurrence(
        now: now,
        weekday: DateTime.tuesday,
        time: const ReminderTime(8, 0),
      );
      expect(next, tz.TZDateTime(sp(), 2026, 11, 10, 8, 0));
    });

    test('mesmo dia já passado vai para a próxima semana', () {
      final now = tz.TZDateTime(sp(), 2026, 11, 10, 9, 0);
      final next = nextWeeklyOccurrence(
        now: now,
        weekday: DateTime.tuesday,
        time: const ReminderTime(8, 0),
      );
      expect(next, tz.TZDateTime(sp(), 2026, 11, 17, 8, 0));
    });

    test('dia da semana seguinte e domingo', () {
      final now = tz.TZDateTime(sp(), 2026, 11, 10, 9, 0);
      expect(
        nextWeeklyOccurrence(
          now: now,
          weekday: DateTime.sunday,
          time: const ReminderTime(21, 30),
        ),
        tz.TZDateTime(sp(), 2026, 11, 15, 21, 30),
      );
    });
  });

  group('planReminders', () {
    final habits = [
      const ReminderHabit(
        id: 3,
        name: 'Ler',
        icon: '📚',
        weekdays: {1, 3, 5},
        reminder: '20:00',
      ),
      const ReminderHabit(
        id: 4,
        name: 'Água',
        icon: '💧',
        weekdays: {1, 2},
        reminder: null,
      ),
    ];
    tz.TZDateTime now() =>
        tz.TZDateTime(tz.getLocation('America/Sao_Paulo'), 2026, 11, 10);

    test('um lembrete por dia agendado, ids estáveis', () {
      final plan = planReminders(habits: habits, now: now(), enabled: true);
      expect(plan.map((p) => p.id), [31, 33, 35]);
      expect(plan.every((p) => p.when.isAfter(now())), isTrue);
      expect(plan.first.title, '📚 Ler');
    });

    test('toggle global desligado não agenda nada', () {
      expect(
        planReminders(habits: habits, now: now(), enabled: false),
        isEmpty,
      );
    });
  });

  group('ReminderService.sync', () {
    const habit = ReminderHabit(
      id: 1,
      name: 'Meditar',
      icon: '🧘',
      weekdays: {1, 2, 3, 4, 5, 6, 7},
      reminder: '07:00',
    );

    test('usa inexato quando alarme exato não é permitido', () async {
      final backend = FakeBackend();
      final count = await ReminderService(backend).sync([habit], enabled: true);
      expect(count, 7);
      expect(backend.scheduled.values.every((e) => e.$2 == false), isTrue);
    });

    test('cai para inexato se o exato falhar', () async {
      final backend = FakeBackend(exact: true, failExact: true);
      final count = await ReminderService(backend).sync([habit], enabled: true);
      expect(count, 7);
      expect(backend.scheduled.values.every((e) => e.$2 == false), isTrue);
    });

    test('editar/excluir: re-sync cancela os antigos', () async {
      final backend = FakeBackend(exact: true);
      final service = ReminderService(backend);
      await service.sync([habit], enabled: true);
      expect(backend.scheduled.length, 7);
      await service.sync([], enabled: true);
      expect(backend.scheduled, isEmpty);
      expect(backend.cancelCalls, 2);
    });
  });
}
