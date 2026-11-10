import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/app.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/theme/habitly_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester, {AppDatabase? database}) async {
    final db = database ?? AppDatabase.memory();
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) {
            ref.onDispose(db.close);
            return db;
          }),
          adsEnabledProvider.overrideWithValue(false),
          reminderSyncEnabledProvider.overrideWithValue(false),
        ],
        child: const HabitlyApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Encerra o ProviderScope e deixa o timer 0ms do Drift disparar.
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('abre a tela Hoje com navegação inferior', (tester) async {
    await pumpApp(tester);
    expect(find.text('Hoje'), findsWidgets);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Nenhum hábito ainda'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('navega entre as abas principais', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Histórico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Histórico'), findsWidgets);

    await tester.tap(find.text('Estatísticas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('As estatísticas aparecem'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('abre o formulário de novo hábito', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(AppBar, 'Novo hábito'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Dias da semana'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lembrete'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Lembrete'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('configurações mostram o toggle de lembretes', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Lembretes de hábitos'), findsOneWidget);
    final toggle = find.byType(Switch);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    await disposeApp(tester);
  });

  testWidgets('mostra hábito existente e marca como concluído', (tester) async {
    final db = AppDatabase.memory();
    await HabitRepository(db).addHabit(
      name: 'Beber água',
      icon: '💧',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );

    await pumpApp(tester, database: db);
    expect(find.text('Beber água'), findsOneWidget);
    final check = find.byKey(const ValueKey('habit-check'));
    expect(check, findsOneWidget);
    expect(find.text('0 de 1 concluídos'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.tap(check);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      if (find.byIcon(Icons.check_circle).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Tudo feito!'), findsOneWidget);
    await disposeApp(tester);
  });
}
