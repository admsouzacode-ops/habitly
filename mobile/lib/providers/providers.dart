import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/reminder_schedule.dart';
import 'package:habitly/services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const freeHabitLimit = 5;
const premiumPrefKey = 'is_premium';
const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// Desliga anúncios em testes de widget / ambientes sem Mobile Ads.
final adsEnabledProvider = Provider<bool>((ref) => true);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider deve ser sobrescrito');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(databaseProvider));
});

final habitSnapshotProvider = StreamProvider<HabitSnapshot>((ref) {
  return ref.watch(habitRepositoryProvider).watchSnapshot();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier(this._prefs) : super(_prefs.getBool(premiumPrefKey) ?? false);

  final SharedPreferences _prefs;

  Future<void> setPremium(bool value) async {
    await _prefs.setBool(premiumPrefKey, value);
    state = value;
  }

  Future<void> toggle() => setPremium(!state);
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref.watch(sharedPreferencesProvider));
});

const remindersPrefKey = 'reminders_enabled';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(LocalNotificationsBackend());
});

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(databaseProvider).watchHabits();
});

class RemindersEnabledNotifier extends StateNotifier<bool> {
  RemindersEnabledNotifier(this._prefs)
    : super(_prefs.getBool(remindersPrefKey) ?? true);

  final SharedPreferences _prefs;

  Future<void> set(bool value) async {
    await _prefs.setBool(remindersPrefKey, value);
    state = value;
  }
}

final remindersEnabledProvider =
    StateNotifierProvider<RemindersEnabledNotifier, bool>((ref) {
      return RemindersEnabledNotifier(ref.watch(sharedPreferencesProvider));
    });

List<ReminderHabit> toReminderHabits(Iterable<Habit> habits) => [
  for (final h in habits)
    ReminderHabit(
      id: h.id,
      name: h.name,
      icon: h.icon,
      weekdays: parseWeekdays(h.weekdays),
      reminder: h.reminder,
    ),
];

/// Mantém as notificações agendadas em sincronia com os hábitos e o toggle.
/// Desligado em testes de widget (sem plugin nativo).
final reminderSyncEnabledProvider = Provider<bool>((ref) => true);

final reminderSyncProvider = Provider<void>((ref) {
  if (!ref.watch(reminderSyncEnabledProvider)) return;
  final enabled = ref.watch(remindersEnabledProvider);
  final habits = ref.watch(habitsProvider).valueOrNull;
  if (habits == null) return;
  ref
      .read(reminderServiceProvider)
      .sync(toReminderHabits(habits), enabled: enabled);
});
