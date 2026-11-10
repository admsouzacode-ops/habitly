import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/logic/habit_stats.dart';

void main() {
  final today = DateTime(2026, 11, 10); // terça-feira
  Set<int> weekdaysOnly() => {1, 2, 3, 4, 5}; // seg-sex
  Set<int> everyday() => {1, 2, 3, 4, 5, 6, 7};

  DateTime d(int day, {int month = 11}) => DateTime(2026, month, day);

  group('currentStreak', () {
    test('zero quando não há dias concluídos', () {
      expect(
        currentStreak(
          weekdays: everyday(),
          completedDays: {},
          today: today,
        ),
        0,
      );
    });

    test('zero quando não há dias agendados', () {
      expect(
        currentStreak(
          weekdays: {},
          completedDays: {today},
          today: today,
        ),
        0,
      );
    });

    test('inclui hoje se já foi concluído', () {
      expect(
        currentStreak(
          weekdays: everyday(),
          completedDays: {d(8), d(9), d(10)},
          today: today,
        ),
        3,
      );
    });

    test('ignora hoje ainda não concluído e conta a partir de ontem', () {
      expect(
        currentStreak(
          weekdays: everyday(),
          completedDays: {d(8), d(9)},
          today: today,
        ),
        2,
      );
    });

    test('pula fins de semana em hábito de dias úteis', () {
      // Hoje terça 10; sexta 6, segunda 9 feitos. Sábado 7 e domingo 8
      // não são agendados e não quebram a sequência.
      expect(
        currentStreak(
          weekdays: weekdaysOnly(),
          completedDays: {d(6), d(9)},
          today: today,
        ),
        2,
      );
    });

    test('quebra se um dia agendado ficou em aberto', () {
      expect(
        currentStreak(
          weekdays: everyday(),
          completedDays: {d(8), d(10)},
          today: today,
        ),
        1,
      );
    });
  });

  group('recordStreak', () {
    test('zero sem conclusões', () {
      expect(
        recordStreak(
          weekdays: everyday(),
          completedDays: {},
          today: today,
        ),
        0,
      );
    });

    test('recorde maior que a sequência atual', () {
      // Sequência antiga de 4 dias (1-4), depois uma falha no dia 5,
      // e sequência atual de 2 (9-10).
      final completed = {d(1), d(2), d(3), d(4), d(9), d(10)};
      expect(
        currentStreak(
          weekdays: everyday(),
          completedDays: completed,
          today: today,
        ),
        2,
      );
      expect(
        recordStreak(
          weekdays: everyday(),
          completedDays: completed,
          today: today,
        ),
        4,
      );
    });

    test('recorde considera dias úteis pulando o fim de semana', () {
      final completed = {d(2), d(3), d(4), d(5), d(6), d(9)};
      expect(
        recordStreak(
          weekdays: weekdaysOnly(),
          completedDays: completed,
          today: today,
        ),
        6,
      );
    });
  });

  group('completionRate', () {
    test('7 dias com todos os dias agendados e metade concluída', () {
      final habits = [
        HabitPresence(
          weekdays: everyday(),
          completedDays: {d(4), d(5), d(6)}, // 3 de 7 (4 a 10)
        ),
      ];
      final rate = completionRate(habits: habits, today: today, windowDays: 7);
      expect(rate.scheduled, 7);
      expect(rate.completed, 3);
      expect(rate.percent, 43);
    });

    test('7 dias só em dias úteis (seg 9 a ter 10 + seg 4 a sex 6 = 5)', () {
      final habits = [
        HabitPresence(
          weekdays: weekdaysOnly(),
          completedDays: {d(6), d(9), d(10)},
        ),
      ];
      final rate = completionRate(habits: habits, today: today, windowDays: 7);
      // Janela 4..10: 4 e 5 (ter,qua) não feitos, 6 (sex) feito,
      // 7-8 fim de semana ignorados, 9-10 feitos. Agendados: 4,5,6,9,10.
      expect(rate.scheduled, 5);
      expect(rate.completed, 3);
      expect(rate.percent, 60);
    });

    test('30 dias soma ocorrências de vários hábitos', () {
      final habits = [
        HabitPresence(weekdays: everyday(), completedDays: {today}),
        HabitPresence(weekdays: everyday(), completedDays: {today}),
      ];
      final rate = completionRate(habits: habits, today: today, windowDays: 30);
      expect(rate.scheduled, 60);
      expect(rate.completed, 2);
    });

    test('janela sem hábitos agendados rende 0%', () {
      final rate = completionRate(
        habits: [HabitPresence(weekdays: {7}, completedDays: {})], // só domingo
        today: DateTime(2026, 11, 9), // segunda... janela 1 dia segunda
        windowDays: 1,
      );
      expect(rate.scheduled, 0);
      expect(rate.completed, 0);
      expect(rate.percent, 0);
    });
  });

  group('overall streak', () {
    test('dia só conta quando todos os hábitos agendados foram feitos', () {
      final habits = [
        HabitPresence(
          weekdays: everyday(),
          completedDays: {d(8), d(9), d(10)},
        ),
        HabitPresence(
          weekdays: everyday(),
          completedDays: {d(8), d(10)}, // faltou o dia 9
        ),
      ];
      expect(overallCurrentStreak(habits: habits, today: today), 1);
      expect(overallRecordStreak(habits: habits, today: today), 1);
    });

    test('dia sem hábito agendado não quebra a sequência', () {
      final habits = [
        HabitPresence(
          weekdays: weekdaysOnly(),
          completedDays: {d(6), d(9), d(10)},
        ),
      ];
      expect(overallCurrentStreak(habits: habits, today: today), 3);
    });
  });
}
