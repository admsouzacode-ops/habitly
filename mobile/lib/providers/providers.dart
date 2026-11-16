import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/billing/billing_gateway.dart';
import 'package:habitly/billing/premium_controller.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/logic/reminder_schedule.dart';
import 'package:habitly/services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const freeHabitLimit = 5;
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

final billingGatewayProvider = Provider<BillingGateway>((ref) {
  return PlayBillingGateway();
});

/// Assinatura Premium (Google Play Billing). Inicie com `.start()` no app.
final premiumControllerProvider =
    StateNotifierProvider<PremiumController, PremiumState>((ref) {
      return PremiumController(
        ref.watch(sharedPreferencesProvider),
        ref.watch(billingGatewayProvider),
      );
    });

/// true = hábitos ilimitados e sem anúncios.
final premiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumControllerProvider.select((s) => s.isPremium));
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

/// Desligado em testes de widget (sem plugin home_widget).
final homeWidgetSyncEnabledProvider = Provider<bool>((ref) => true);

class AchievementLedgerNotifier extends StateNotifier<AchievementLedger> {
  AchievementLedgerNotifier(this._prefs)
    : super(
        AchievementLedger.decode(_prefs.getString(AchievementLedger.prefKey)),
      );

  final SharedPreferences _prefs;

  /// Registra as conquistas recém-alcançadas e devolve só as novas.
  Future<List<Achievement>> record(Set<String> computed) async {
    final fresh = state.newlyUnlocked(computed);
    if (fresh.isEmpty) return fresh;
    state = state.merge(fresh.map((a) => a.id), DateTime.now());
    await _prefs.setString(AchievementLedger.prefKey, state.encode());
    return fresh;
  }
}

final achievementLedgerProvider =
    StateNotifierProvider<AchievementLedgerNotifier, AchievementLedger>((ref) {
      return AchievementLedgerNotifier(ref.watch(sharedPreferencesProvider));
    });
