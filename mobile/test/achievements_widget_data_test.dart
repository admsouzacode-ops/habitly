import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/achievements.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/logic/note_reasons.dart';
import 'package:habitly/services/home_widget_service.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  final today = DateTime(2026, 11, 10); // terça

  setUp(() {
    db = AppDatabase.memory();
    repo = HabitRepository(db);
  });
  tearDown(() => db.close());

  Future<Habit> add(
    String name, {
    HabitGoal goal = const HabitGoal(),
    DateTime? createdAt,
  }) async {
    final id = await repo.addHabit(
      name: name,
      icon: '⭐',
      colorValue: 0xFF1B7A4B,
      weekdays: goal.weekdays,
      goal: goal,
    );
    if (createdAt != null) {
      await db.updateHabitRow(id, HabitsCompanion(createdAt: Value(createdAt)));
    }
    return (await db.getHabits()).firstWhere((h) => h.id == id);
  }

  Future<void> doneOn(Habit h, Iterable<DateTime> days) async {
    for (final d in days) {
      await repo.setCompleted(habitId: h.id, day: d, completed: true);
    }
  }

  group('conquistas', () {
    test('sem dados nada desbloqueia', () async {
      final s = await repo.loadSnapshot();
      expect(computeUnlocked(s, today), isEmpty);
    });

    test('primeiro hábito, primeira conclusão e sequência de 3', () async {
      final h = await add('Ler');
      var s = await repo.loadSnapshot();
      expect(computeUnlocked(s, today), {'primeiro_habito'});

      await doneOn(h, [addDays(today, -2), addDays(today, -1), today]);
      s = await repo.loadSnapshot();
      final unlocked = computeUnlocked(s, today);
      expect(unlocked, containsAll(['primeira_conclusao', 'sequencia_3']));
      expect(unlocked, isNot(contains('sequencia_7')));
      expect(achievementProgress(s, today)['sequencia_7'], 3);
    });

    test('total de 50 conclusões e sequência de 30', () async {
      final h = await add('Água');
      await doneOn(h, [for (var i = 0; i < 50; i++) addDays(today, -i)]);
      final s = await repo.loadSnapshot();
      final unlocked = computeUnlocked(s, today);
      expect(unlocked, containsAll(['total_50', 'sequencia_30']));
      expect(unlocked, isNot(contains('total_100')));
      expect(unlocked, isNot(contains('sequencia_100')));
    });

    test('semana perfeita exige a semana inteira encerrada', () async {
      final h = await add('Correr', createdAt: DateTime(2026, 10, 1));
      // Semana de 02/11 a 08/11 completa.
      await doneOn(h, [for (var i = 2; i <= 8; i++) DateTime(2026, 11, i)]);
      var s = await repo.loadSnapshot();
      expect(hasPerfectWeek(s, today), isTrue);

      // Só a semana atual (incompleta) não conta.
      await db.delete(db.completions).go();
      await doneOn(h, [DateTime(2026, 11, 9), today]);
      s = await repo.loadSnapshot();
      expect(hasPerfectWeek(s, today), isFalse);
    });

    test('semana perfeita falha com um dia agendado faltando', () async {
      final h = await add('Correr', createdAt: DateTime(2026, 10, 1));
      await doneOn(h, [
        for (var i = 2; i <= 8; i++)
          if (i != 5) DateTime(2026, 11, i),
      ]);
      final s = await repo.loadSnapshot();
      expect(hasPerfectWeek(s, today), isFalse);
    });

    test(
      'meta semanal 4 semanas seguidas, meta de quantidade e nota',
      () async {
        final w = await add(
          'Academia',
          goal: const HabitGoal(type: GoalType.weekly, weeklyTarget: 2),
        );
        await doneOn(w, [
          for (final monday in [
            DateTime(2026, 10, 19),
            DateTime(2026, 10, 26),
            DateTime(2026, 11, 2),
            DateTime(2026, 11, 9),
          ]) ...[monday, addDays(monday, 1)],
        ]);
        final q = await add(
          'Água',
          goal: const HabitGoal(
            type: GoalType.quantity,
            quantityTarget: 2,
            quantityUnit: 'litros',
          ),
        );
        await repo.setAmount(habit: q, day: today, amount: 2);
        await repo.saveNote(
          habitId: w.id,
          day: today,
          note: '',
          reason: NoteReason.cansaco,
        );
        final s = await repo.loadSnapshot();
        final unlocked = computeUnlocked(s, today);
        expect(
          unlocked,
          containsAll(['meta_semanal_4', 'meta_quantidade', 'primeira_nota']),
        );
      },
    );

    test('registro guarda a data e só devolve as novas', () {
      var ledger = AchievementLedger.decode(null);
      expect(ledger.newlyUnlocked({'primeiro_habito'}).map((a) => a.id), [
        'primeiro_habito',
      ]);
      ledger = ledger.merge(['primeiro_habito'], DateTime(2026, 11, 1));
      final restored = AchievementLedger.decode(ledger.encode());
      expect(restored.isUnlocked('primeiro_habito'), isTrue);
      expect(restored.unlockedAt['primeiro_habito'], DateTime(2026, 11, 1));
      expect(
        restored
            .newlyUnlocked({'primeiro_habito', 'primeira_nota'})
            .map((a) => a.id),
        ['primeira_nota'],
      );
      expect(AchievementLedger.decode('lixo').unlockedAt, isEmpty);
    });
  });

  group('metas semanais e de quantidade', () {
    test('semanal aparece hoje até bater a meta', () async {
      final w = await add(
        'Academia',
        goal: const HabitGoal(type: GoalType.weekly, weeklyTarget: 2),
      );
      expect(w.weekdays, '1,2,3,4,5,6,7');
      var s = await repo.loadSnapshot();
      expect(s.isDueOn(w, today), isTrue);
      await doneOn(w, [DateTime(2026, 11, 9)]);
      s = await repo.loadSnapshot();
      expect(s.weekCount(w.id, today), 1);
      expect(s.isDueOn(w, today), isTrue);
      await doneOn(w, [today]);
      s = await repo.loadSnapshot();
      expect(s.weeklyGoalMet(w, today), isTrue);
      expect(s.isDueOn(w, today), isTrue); // feito hoje continua na lista
      expect(s.isDueOn(w, addDays(today, 1)), isFalse);
      // No histórico só aparece nos dias em que foi feito.
      expect(s.habitsScheduledOn(addDays(today, -3)), isEmpty);
    });

    test(
      'quantidade conclui só ao atingir a meta e desfaz ao diminuir',
      () async {
        final q = await add(
          'Copos',
          goal: const HabitGoal(
            type: GoalType.quantity,
            quantityTarget: 8,
            quantityUnit: 'copos',
          ),
        );
        for (var i = 0; i < 7; i++) {
          await repo.quickAction(habit: q, day: today);
        }
        var s = await repo.loadSnapshot();
        expect(s.amountFor(q.id, today), 7);
        expect(s.isCompleted(q.id, today), isFalse);
        await repo.quickAction(habit: q, day: today);
        s = await repo.loadSnapshot();
        expect(s.isCompleted(q.id, today), isTrue);
        await repo.addAmount(habit: q, day: today, delta: -1);
        s = await repo.loadSnapshot();
        expect(s.isCompleted(q.id, today), isFalse);
        await repo.setAmount(habit: q, day: today, amount: -5);
        s = await repo.loadSnapshot();
        expect(s.amountFor(q.id, today), 0);
      },
    );

    test('mudar a meta reavalia o dia de hoje', () async {
      final now = dateOnly(DateTime.now());
      final q = await add(
        'Água',
        goal: const HabitGoal(type: GoalType.quantity, quantityTarget: 3),
      );
      await repo.setAmount(habit: q, day: now, amount: 2);
      await repo.updateHabit(
        id: q.id,
        name: 'Água',
        icon: '💧',
        colorValue: 0xFF1B7A4B,
        weekdays: allWeekdays,
        goal: const HabitGoal(type: GoalType.quantity, quantityTarget: 2),
      );
      final s = await repo.loadSnapshot();
      expect(s.isCompleted(q.id, now), isTrue);
    });
  });

  group('dados do widget', () {
    test('lista os hábitos de hoje com progresso e ação', () async {
      final daily = await add('Ler');
      final q = await add(
        'Água',
        goal: const HabitGoal(
          type: GoalType.quantity,
          quantityTarget: 2,
          quantityUnit: 'litros',
          quantityStep: 0.5,
        ),
      );
      final w = await add(
        'Academia',
        goal: const HabitGoal(type: GoalType.weekly, weeklyTarget: 3),
      );
      await add('Só segunda', goal: const HabitGoal(weekdays: {1}));
      await repo.setAmount(habit: q, day: today, amount: 1);
      await doneOn(daily, [today]);

      final data = buildWidgetData(await repo.loadSnapshot(), today);
      expect(data.date, '2026-11-10');
      expect(data.header, 'Hoje · 1/3');
      expect(data.extra, 0);
      // Pendentes primeiro.
      expect(data.rows.map((r) => r.habitId), [q.id, w.id, daily.id]);
      final water = data.rows.first;
      expect(water.progress, '1/2 litros');
      expect(water.action, WidgetAction.plus);
      expect(water.actionLabel, '+0,5');
      expect(data.rows[1].progress, '0/3 sem.');
      expect(data.rows[1].action, WidgetAction.toggle);
      expect(data.rows[2].done, isTrue);
      expect(data.rows[2].progress, 'Feito');
    });

    test('limita a 5 linhas e informa o restante', () async {
      for (var i = 0; i < 7; i++) {
        await add('Hábito $i');
      }
      final data = buildWidgetData(await repo.loadSnapshot(), today);
      expect(data.rows, hasLength(widgetMaxRows));
      expect(data.extra, 2);
    });

    test('sem hábitos mostra convite', () async {
      final data = buildWidgetData(await repo.loadSnapshot(), today);
      expect(data.rows, isEmpty);
      expect(data.emptyMessage, contains('primeiro hábito'));
    });
  });
}
