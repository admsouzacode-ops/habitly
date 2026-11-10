import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habitly/logic/reminder_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const defaultTimezone = 'America/Sao_Paulo';
const reminderChannelId = 'habit_reminders';
const reminderChannelName = 'Lembretes de hábitos';

/// Abstração do agendador para permitir testes sem plugin nativo.
abstract class ReminderBackend {
  Future<void> init();
  tz.Location get location;
  Future<bool> requestPermission();
  Future<bool> canScheduleExact();
  Future<bool> requestExactPermission();
  Future<void> cancelAll();
  Future<void> scheduleWeekly(PlannedReminder reminder, {required bool exact});
}

class ReminderService {
  ReminderService(this._backend);

  final ReminderBackend _backend;
  Future<void>? _initFuture;
  Future<void> _queue = Future.value();

  Future<void> _ensureInit() => _initFuture ??= _backend.init();

  Future<bool> requestPermission() async {
    try {
      await _ensureInit();
      return await _backend.requestPermission();
    } catch (e, s) {
      debugPrint('Permissão de notificação falhou: $e\n$s');
      return false;
    }
  }

  Future<bool> canScheduleExact() async {
    try {
      await _ensureInit();
      return await _backend.canScheduleExact();
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestExactPermission() async {
    try {
      await _ensureInit();
      return await _backend.requestExactPermission();
    } catch (e) {
      debugPrint('Permissão de alarme exato falhou: $e');
      return false;
    }
  }

  /// Cancela tudo e reagenda conforme os hábitos atuais. Idempotente; as
  /// chamadas são serializadas para não intercalar cancel/schedule.
  Future<int> sync(Iterable<ReminderHabit> habits, {required bool enabled}) {
    final list = habits.toList();
    final next = _queue.then((_) => _syncNow(list, enabled));
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<int> _syncNow(List<ReminderHabit> habits, bool enabled) async {
    try {
      await _ensureInit();
      await _backend.cancelAll();
      final plan = planReminders(
        habits: habits,
        now: tz.TZDateTime.now(_backend.location),
        enabled: enabled,
      );
      if (plan.isEmpty) return 0;
      final exact = await _backend.canScheduleExact();
      var scheduled = 0;
      for (final reminder in plan) {
        try {
          await _backend.scheduleWeekly(reminder, exact: exact);
          scheduled++;
        } catch (e) {
          if (!exact) rethrow;
          // Alarme exato negado entre a checagem e o agendamento: cai pro inexato.
          await _backend.scheduleWeekly(reminder, exact: false);
          scheduled++;
        }
      }
      return scheduled;
    } catch (e, s) {
      debugPrint('Falha ao agendar lembretes: $e\n$s');
      return 0;
    }
  }
}

class LocalNotificationsBackend implements ReminderBackend {
  final _plugin = FlutterLocalNotificationsPlugin();
  tz.Location _location = tz.UTC;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  tz.Location get location => _location;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      _location = tz.getLocation(info.identifier);
    } catch (_) {
      _location = tz.getLocation(defaultTimezone);
    }
    tz.setLocalLocation(_location);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_habitly'),
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannelId,
        reminderChannelName,
        description: 'Avisos no horário escolhido para cada hábito.',
        importance: Importance.high,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<bool> requestExactPermission() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> scheduleWeekly(PlannedReminder reminder, {required bool exact}) {
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: reminder.when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: 'Avisos no horário escolhido para cada hábito.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_habitly',
          color: Color(0xFF1B7A4B),
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'habit:${reminder.habitId}',
    );
  }
}
