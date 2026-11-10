import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:habitly/logic/habit_stats.dart';

DateTime d(int month, int day) => DateTime(2026, month, day);

void main() {
  // Novembro/2026: dia 2 = segunda, 8 = domingo, 9 = segunda, 10 = terça.
  group('datas', () {
    test('weekStart é a segunda-feira ISO', () {
      expect(weekStart(d(11, 10)), d(11, 9));
      expect(weekStart(d(11, 8)), d(11, 2));
      expect(weekStart(d(11, 9)), d(11, 9));
      expect(addDays(d(10, 31), 1), d(11, 1));
    });
  });

  group('formatação de quantidades', () {
    test('pt-BR sem zeros à toa', () {
      expect(formatAmount(2), '2');
      expect(formatAmount(1.5), '1,5');
      expect(formatAmount(0.25), '0,25');
      expect(parseAmount('1,5'), 1.5);
      expect(parseAmount('2.25'), 2.25);
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
    });

    test('resumo da meta', () {
      expect(const HabitGoal().summary(), 'Todos os dias');
      expect(
        const HabitGoal(weekdays: {1, 2, 3, 4, 5}).summary(),
        'Dias úteis',
      );
      expect(
        const HabitGoal(type: GoalType.weekly, weeklyTarget: 3).summary(),
        '3x por semana',
      );
      expect(
        const HabitGoal(
          type: GoalType.quantity,
          quantityTarget: 2,
          quantityUnit: 'litros',
        ).summary(),
        '2 litros por dia',
      );
      expect(GoalType.parse('weekly'), GoalType.weekly);
      expect(GoalType.parse(null), GoalType.daily);
      expect(GoalType.parse('lixo'), GoalType.daily);
    });
  });

  group('sequência diária / quantidade', () {
    test('dias fora da agenda não quebram a sequência', () {
      // Seg/Qua/Sex. Feito seg 2, qua 4, sex 6, seg 9.
      const goal = HabitGoal(weekdays: {1, 3, 5});
      final info = streakFor(
        goal: goal,
        completedDays: {d(11, 2), d(11, 4), d(11, 6), d(11, 9)},
        today: d(11, 10), // terça, não agendada
      );
      expect(info.unit, StreakUnit.days);
      expect(info.current, 4);
      expect(info.best, 4);
      expect(info.currentText, '🔥 4 dias seguidos');
    });

    test('hoje pendente não quebra; falta agendada quebra', () {
      const goal = HabitGoal();
      final days = {d(11, 5), d(11, 6), d(11, 8), d(11, 9)};
      final info = streakFor(goal: goal, completedDays: days, today: d(11, 10));
      expect(info.current, 2); // 8 e 9 (dia 7 faltou)
      expect(info.best, 2);
      final done = streakFor(
        goal: goal,
        completedDays: {...days, d(11, 10)},
        today: d(11, 10),
      );
      expect(done.current, 3);
    });

    test('quantidade usa os dias concluídos (meta batida)', () {
      const goal = HabitGoal(type: GoalType.quantity, quantityTarget: 8);
      final info = streakFor(
        goal: goal,
        completedDays: {d(11, 8), d(11, 9), d(11, 10)},
        today: d(11, 10),
      );
      expect(info.unit, StreakUnit.days);
      expect(info.current, 3);
    });
  });

  group('sequência semanal', () {
    const goal = HabitGoal(type: GoalType.weekly, weeklyTarget: 3);

    test(
      'conta semanas com a meta batida; semana atual em andamento não quebra',
      () {
        final days = {
          // Semana de 26/10: 3x
          d(10, 26), d(10, 28), d(10, 30),
          // Semana de 02/11: 3x
          d(11, 2), d(11, 3), d(11, 8),
          // Semana atual (09/11): 1x até agora
          d(11, 9),
        };
        final info = streakFor(
          goal: goal,
          completedDays: days,
          today: d(11, 10),
        );
        expect(info.unit, StreakUnit.weeks);
        expect(info.current, 2);
        expect(info.best, 2);
        expect(info.currentText, '🔥 2 semanas seguidas');
      },
    );

    test('semana atual entra quando bate a meta', () {
      final days = {
        d(11, 2),
        d(11, 3),
        d(11, 4),
        d(11, 9),
        d(11, 10),
        d(11, 11),
      };
      final info = streakFor(goal: goal, completedDays: days, today: d(11, 11));
      expect(info.current, 2);
    });

    test('semana passada abaixo da meta zera a atual, recorde fica', () {
      final days = {
        d(10, 19), d(10, 20), d(10, 21),
        d(10, 26), d(10, 27), d(10, 28),
        d(11, 2), // só 1x na semana de 02/11
        d(11, 9),
      };
      final info = streakFor(goal: goal, completedDays: days, today: d(11, 10));
      expect(info.current, 0);
      expect(info.best, 2);
    });

    test('conclusões acima da meta não somam semanas extras', () {
      final days = {for (var i = 2; i <= 8; i++) d(11, i)};
      final info = streakFor(goal: goal, completedDays: days, today: d(11, 10));
      expect(info.current, 1);
      expect(completionsInWeek(days, d(11, 5)), 7);
    });
  });

  group('presença semanal nas métricas', () {
    test('semanal não cria falta diária na sequência geral', () {
      final daily = HabitPresence(
        weekdays: allWeekdays,
        completedDays: {d(11, 8), d(11, 9), d(11, 10)},
      );
      final weekly = HabitPresence(
        weekdays: allWeekdays,
        completedDays: {d(11, 9)},
        weeklyTarget: 3,
      );
      expect(
        overallCurrentStreak(habits: [daily, weekly], today: d(11, 10)),
        3,
      );
    });

    test('taxa em 7 dias conta a semana do hábito semanal', () {
      // Janela 04/11..10/11 toca as semanas de 02/11 (meta 3, feito 2 dentro
      // da janela) e 09/11 (em andamento, 1 feito).
      final weekly = HabitPresence(
        weekdays: allWeekdays,
        completedDays: {d(11, 5), d(11, 6), d(11, 9)},
        weeklyTarget: 3,
      );
      final rate = completionRate(
        habits: [weekly],
        today: d(11, 10),
        windowDays: 7,
      );
      expect(rate.scheduled, 4); // 3 (semana fechada) + 1 (em andamento)
      expect(rate.completed, 3);
    });
  });
}
