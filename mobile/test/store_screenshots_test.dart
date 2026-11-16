// Gera as capturas da Play Store a partir das telas reais do app.
// Rodar com: STORE_SHOTS=/workspace/habitly-store/raw flutter test test/store_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/app.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/logic/note_reasons.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/screens/achievements_screen.dart';
import 'package:habitly/screens/home_shell.dart';
import 'package:habitly/screens/paywall_screen.dart';
import 'package:habitly/theme/habitly_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_billing.dart';
import 'support/fonts.dart';

final outDir = Platform.environment['STORE_SHOTS'];

void main() {
  setUpAll(() => loadRealFonts(emoji: true));

  Future<AppDatabase> seed() async {
    final db = AppDatabase.memory();
    final repo = HabitRepository(db);
    final today = dateOnly(DateTime.now());
    final start = addDays(today, -45);
    var order = 0;
    Future<Habit> add(
      String name,
      String icon,
      Color color,
      HabitGoal g,
    ) async {
      final id = await repo.addHabit(
        name: name,
        icon: icon,
        colorValue: color.toARGB32(),
        weekdays: g.weekdays,
        goal: g,
        reminder: '07:30',
      );
      await db.updateHabitRow(
        id,
        HabitsCompanion(
          createdAt: Value(start.add(Duration(minutes: order++))),
        ),
      );
      return (await db.getHabits()).firstWhere((h) => h.id == id);
    }

    final agua = await add(
      'Beber água 2 litros',
      '💧',
      habitColorPalette[2],
      const HabitGoal(
        type: GoalType.quantity,
        quantityTarget: 2,
        quantityUnit: 'litros',
        quantityStep: 0.25,
      ),
    );
    final ler = await add(
      'Ler 20 min',
      '📚',
      habitColorPalette[3],
      const HabitGoal(),
    );
    final academia = await add(
      'Academia 3x/semana',
      '🏋️',
      habitColorPalette[5],
      const HabitGoal(type: GoalType.weekly, weeklyTarget: 3),
    );
    final meditar = await add(
      'Meditar',
      '🧘',
      habitColorPalette[1],
      const HabitGoal(),
    );

    for (var d = start; d.isBefore(today); d = addDays(d, 1)) {
      final n = today.difference(d).inDays;
      await repo.setAmount(habit: agua, day: d, amount: n % 9 == 4 ? 1.5 : 2);
      if (n % 11 != 7) {
        await repo.setCompleted(habitId: ler.id, day: d, completed: true);
      }
      if ({1, 3, 5}.contains(d.weekday) || (n % 13 == 2)) {
        await repo.setCompleted(habitId: academia.id, day: d, completed: true);
      }
      if (n % 6 != 3) {
        await repo.setCompleted(habitId: meditar.id, day: d, completed: true);
      } else {
        await repo.saveNote(
          habitId: meditar.id,
          day: d,
          note: n % 12 == 3 ? 'Reunião cedo' : '',
          reason: n % 12 == 3 ? NoteReason.semTempo : NoteReason.cansaco,
        );
      }
    }
    await repo.setAmount(habit: agua, day: today, amount: 1.25);
    await repo.setCompleted(habitId: ler.id, day: today, completed: true);
    await repo.setCompleted(habitId: academia.id, day: today, completed: true);
    return db;
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 600));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(
        pixelRatio: tester.view.devicePixelRatio,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester, [int frames = 30]) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('capturas da loja', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.7; // 400 x 711 dp
    addTearDown(tester.view.reset);

    final db = await seed();
    final snapshot = await HabitRepository(db).loadSnapshot();
    final unlocked = computeUnlocked(snapshot, DateTime.now());
    SharedPreferences.setMockInitialValues({
      AchievementLedger.prefKey: AchievementLedger({
        for (final id in unlocked)
          id: dateOnly(DateTime.now()).subtract(const Duration(days: 3)),
      }).encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWith((ref) {
              ref.onDispose(db.close);
              return db;
            }),
            adsEnabledProvider.overrideWithValue(false),
            reminderSyncEnabledProvider.overrideWithValue(false),
            homeWidgetSyncEnabledProvider.overrideWithValue(false),
            billingGatewayProvider.overrideWithValue(FakeBillingGateway()),
          ],
          child: HabitlyApp(theme: _shotTheme()),
        ),
      ),
    );
    await settle(tester);
    await shoot(tester, '01-hoje');

    await tester.tap(find.text('Histórico'));
    await settle(tester);
    await shoot(tester, '02-historico');

    await tester.tap(find.text('Estatísticas'));
    await settle(tester);
    await shoot(tester, '03-estatisticas');

    final nav = Navigator.of(tester.element(find.byType(HomeShell)));
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
    );
    await settle(tester);
    await shoot(tester, '04-conquistas');
    nav.pop();
    await settle(tester, 10);

    await tester.tap(find.text('Hoje').last);
    await settle(tester, 10);
    final meditar = find.text('Meditar');
    await tester.longPress(meditar);
    await settle(tester);
    await shoot(tester, '05-nota');
    nav.pop();
    await settle(tester, 10);

    nav.push(MaterialPageRoute<void>(builder: (_) => const PaywallScreen()));
    await settle(tester);
    await shoot(tester, '06-premium');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }, skip: outDir == null);
}

ThemeData _shotTheme() => buildHabitlyTheme(
  fontFamily: 'Roboto',
  fontFamilyFallback: const ['NotoColorEmoji'],
);
