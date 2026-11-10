import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/app.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/logic/note_reasons.dart';
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
          homeWidgetSyncEnabledProvider.overrideWithValue(false),
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

  Finder formScrollable() => find
      .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
      .first;

  testWidgets('abre o formulário de novo hábito', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(AppBar, 'Novo hábito'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Meta'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dias da semana'),
      200,
      scrollable: formScrollable(),
    );
    expect(find.text('Dias da semana'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lembrete'),
      200,
      scrollable: formScrollable(),
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

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (until.evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('escreve nota do dia pelo card e mostra indicador', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    final id = await HabitRepository(db).addHabit(
      name: 'Correr',
      icon: '🏃',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    await pumpApp(tester, database: db);
    expect(find.byKey(const ValueKey('note-indicator')), findsNothing);

    await tester.tap(find.byKey(ValueKey('habit-note-$id')));
    await settle(tester, find.text('Por que não consegui?'));
    expect(find.text('Por que não consegui?'), findsOneWidget);
    for (final label in [
      'Sem tempo',
      'Cansaço',
      'Esqueci',
      'Doente',
      'Imprevisto',
      'Outro',
    ]) {
      expect(find.textContaining(label), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('reason-cansaco')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('note-text')),
      'Dormi mal',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('note-save')));
    await settle(tester, find.byKey(const ValueKey('note-indicator')));

    expect(find.byKey(const ValueKey('note-indicator')), findsOneWidget);
    expect(find.text('Cansaço · Dormi mal'), findsOneWidget);
    final saved = await db.allNotes();
    expect(saved.single.reason, 'cansaco');
    expect(saved.single.note, 'Dormi mal');

    // Reabre e exclui.
    await tester.tap(find.byKey(ValueKey('habit-note-$id')));
    await settle(tester, find.byKey(const ValueKey('note-delete')));
    await tester.tap(find.byKey(const ValueKey('note-delete')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const ValueKey('note-indicator')).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('note-indicator')), findsNothing);
    expect(await db.allNotes(), isEmpty);
    await disposeApp(tester);
  });

  testWidgets('histórico e estatísticas mostram as notas', (tester) async {
    final db = AppDatabase.memory();
    final repo = HabitRepository(db);
    final id = await repo.addHabit(
      name: 'Ler',
      icon: '📚',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    await repo.saveNote(
      habitId: id,
      day: DateTime.now(),
      note: 'Trabalho até tarde',
      reason: NoteReason.semTempo,
    );
    await pumpApp(tester, database: db);

    await tester.tap(find.text('Histórico'));
    await settle(tester, find.text('Sem tempo · Trabalho até tarde'));
    expect(find.text('Sem tempo · Trabalho até tarde'), findsOneWidget);

    await tester.tap(find.text('Estatísticas'));
    await settle(tester, find.text('Motivos mais comuns'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reasons-section')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Motivos mais comuns'), findsOneWidget);
    expect(find.text('⏰ Sem tempo'), findsOneWidget);
    expect(find.text('1 nota'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('estatísticas sem notas mostram estado vazio', (tester) async {
    final db = AppDatabase.memory();
    await HabitRepository(db).addHabit(
      name: 'Ler',
      icon: '📚',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1},
    );
    await pumpApp(tester, database: db);
    await tester.tap(find.text('Estatísticas'));
    await settle(tester, find.text('Motivos mais comuns'));
    await tester.scrollUntilVisible(
      find.textContaining('Nenhuma nota ainda'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Nenhuma nota ainda'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('cria hábito de quantidade pelo formulário e soma no card', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    await pumpApp(tester, database: db);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, find.text('Meta'));
    await tester.enterText(find.byType(TextFormField).first, 'Beber água');
    await tester.tap(find.text('Quantidade'));
    await tester.pump();
    Future<void> type(String key, String text) async {
      final f = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(f, 150, scrollable: formScrollable());
      await tester.enterText(f, text);
      await tester.pump();
    }

    await type('quantity-target', '2');
    await type('quantity-unit', 'litros');
    await type('quantity-step', '0,5');
    await tester.scrollUntilVisible(
      find.text('Criar hábito'),
      200,
      scrollable: formScrollable(),
    );
    await tester.tap(find.text('Criar hábito'));
    await settle(tester, find.text('Beber água'));

    final habit = (await db.getHabits()).single;
    expect(goalOf(habit).summary(), '2 litros por dia');
    expect(habit.goalType, 'quantity');
    expect(habit.quantityTarget, 2);
    expect(habit.quantityUnit, 'litros');
    expect(habit.quantityStep, 0.5);

    final status = find.byKey(ValueKey('habit-status-${habit.id}'));
    expect(tester.widget<Text>(status).data, '0/2 litros');
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(ValueKey('habit-plus-${habit.id}')));
      await tester.pump();
      await settle(tester, find.byKey(ValueKey('habit-status-${habit.id}')));
    }
    expect(tester.widget<Text>(status).data, startsWith('2/2 litros'));
    expect(find.text('Tudo feito!'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('hábito semanal mostra progresso da semana', (tester) async {
    final db = AppDatabase.memory();
    final id = await HabitRepository(db).addHabit(
      name: 'Academia',
      icon: '🏋️',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
      goal: const HabitGoal(type: GoalType.weekly, weeklyTarget: 3),
    );
    await pumpApp(tester, database: db);
    final status = find.byKey(ValueKey('habit-status-$id'));
    expect(tester.widget<Text>(status).data, '0/3 esta semana');
    await tester.tap(find.byKey(const ValueKey('habit-check')));
    await settle(tester, find.text('Tudo feito!'));
    expect(tester.widget<Text>(status).data, startsWith('1/3 esta semana'));
    await disposeApp(tester);
  });

  testWidgets('conquista celebra e abre a tela de Conquistas', (tester) async {
    final db = AppDatabase.memory();
    await HabitRepository(db).addHabit(
      name: 'Ler',
      icon: '📚',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    await pumpApp(tester, database: db);
    await settle(tester, find.byKey(const ValueKey('achievement-snackbar')));
    expect(find.textContaining('Primeiro passo'), findsOneWidget);
    // Some sozinho (não pode cobrir o botão "Novo hábito").
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('achievement-snackbar')), findsNothing);

    await tester.tap(find.text('Estatísticas'));
    await settle(tester, find.byKey(const ValueKey('open-achievements')));
    await tester.tap(find.byKey(const ValueKey('open-achievements')));
    await settle(tester, find.text('Conquistas'));
    expect(find.text('1 de ${achievements.length} conquistas'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('achievement-primeiro_habito')),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  testWidgets('toque no card abre os detalhes com sequência', (tester) async {
    final db = AppDatabase.memory();
    final repo = HabitRepository(db);
    final id = await repo.addHabit(
      name: 'Meditar',
      icon: '🧘',
      colorValue: habitColorPalette.first.toARGB32(),
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    final today = DateTime.now();
    for (var i = 1; i <= 3; i++) {
      await repo.setCompleted(
        habitId: id,
        day: today.subtract(Duration(days: i)),
        completed: true,
      );
    }
    await pumpApp(tester, database: db);
    expect(find.text('🔥 3 dias seguidos'), findsOneWidget);
    await tester.tap(find.text('Meditar'));
    await settle(tester, find.text('Sequência atual'));
    expect(find.text('Sequência atual'), findsOneWidget);
    expect(find.text('Recorde'), findsOneWidget);
    expect(find.text('Todos os dias'), findsOneWidget);
    await disposeApp(tester);
  });
}
