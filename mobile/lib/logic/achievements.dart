import 'dart:convert';

import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/habit_stats.dart';

/// Medalhas do Habitly (grátis para todos os planos).
class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.goal,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;

  /// Valor que desbloqueia (para a barra de progresso).
  final int goal;
}

const achievements = <Achievement>[
  Achievement(
    id: 'primeiro_habito',
    emoji: '🌱',
    title: 'Primeiro passo',
    description: 'Crie seu primeiro hábito.',
    goal: 1,
  ),
  Achievement(
    id: 'primeira_conclusao',
    emoji: '✅',
    title: 'Começou!',
    description: 'Conclua um hábito pela primeira vez.',
    goal: 1,
  ),
  Achievement(
    id: 'sequencia_3',
    emoji: '🔥',
    title: 'Esquentando',
    description: '3 dias seguidos em um hábito.',
    goal: 3,
  ),
  Achievement(
    id: 'sequencia_7',
    emoji: '⚡',
    title: 'Semana firme',
    description: '7 dias seguidos em um hábito.',
    goal: 7,
  ),
  Achievement(
    id: 'sequencia_30',
    emoji: '🏅',
    title: 'Mês de ouro',
    description: '30 dias seguidos em um hábito.',
    goal: 30,
  ),
  Achievement(
    id: 'sequencia_100',
    emoji: '💎',
    title: 'Centenário',
    description: '100 dias seguidos em um hábito.',
    goal: 100,
  ),
  Achievement(
    id: 'total_50',
    emoji: '⭐',
    title: '50 conclusões',
    description: 'Some 50 conclusões em todos os hábitos.',
    goal: 50,
  ),
  Achievement(
    id: 'total_100',
    emoji: '🌟',
    title: '100 conclusões',
    description: 'Some 100 conclusões em todos os hábitos.',
    goal: 100,
  ),
  Achievement(
    id: 'semana_perfeita',
    emoji: '🏆',
    title: 'Semana perfeita',
    description: 'Cumpra todos os hábitos de uma semana, de segunda a domingo.',
    goal: 1,
  ),
  Achievement(
    id: 'meta_semanal_4',
    emoji: '📆',
    title: 'Constância semanal',
    description: 'Bata uma meta semanal 4 semanas seguidas.',
    goal: 4,
  ),
  Achievement(
    id: 'meta_quantidade',
    emoji: '💧',
    title: 'Meta batida',
    description: 'Atinja a meta de um hábito de quantidade.',
    goal: 1,
  ),
  Achievement(
    id: 'primeira_nota',
    emoji: '📝',
    title: 'Autoconhecimento',
    description: 'Registre a primeira nota do dia.',
    goal: 1,
  ),
];

Achievement? achievementById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}

/// Progresso atual de cada conquista (valor já alcançado, limitado à meta
/// só na exibição).
Map<String, int> achievementProgress(HabitSnapshot s, DateTime today) {
  final day = dateOnly(today);
  var bestDayStreak = 0;
  var bestWeekStreak = 0;
  var quantityHits = 0;
  for (final habit in s.habits) {
    final goal = s.goalFor(habit);
    final streak = s.streakOf(habit, day);
    if (goal.isWeekly) {
      if (streak.best > bestWeekStreak) bestWeekStreak = streak.best;
    } else if (streak.best > bestDayStreak) {
      bestDayStreak = streak.best;
    }
    if (goal.isQuantity) {
      quantityHits += s.completions.where((c) => c.habitId == habit.id).length;
    }
  }
  final total = s.completions.length;
  return {
    'primeiro_habito': s.habits.length,
    'primeira_conclusao': total,
    'sequencia_3': bestDayStreak,
    'sequencia_7': bestDayStreak,
    'sequencia_30': bestDayStreak,
    'sequencia_100': bestDayStreak,
    'total_50': total,
    'total_100': total,
    'semana_perfeita': hasPerfectWeek(s, day) ? 1 : 0,
    'meta_semanal_4': bestWeekStreak,
    'meta_quantidade': quantityHits,
    'primeira_nota': s.notes.length,
  };
}

/// Conquistas alcançadas pelos dados atuais.
Set<String> computeUnlocked(HabitSnapshot s, DateTime today) {
  final progress = achievementProgress(s, today);
  return {
    for (final a in achievements)
      if ((progress[a.id] ?? 0) >= a.goal) a.id,
  };
}

/// Existe alguma semana ISO já encerrada (domingo <= hoje) em que todo
/// hábito diário/quantidade foi feito em todos os dias agendados e toda meta
/// semanal foi batida? Hábitos criados no meio da semana não entram nela.
/// Precisa de pelo menos um hábito avaliado na semana.
bool hasPerfectWeek(HabitSnapshot s, DateTime today) {
  if (s.habits.isEmpty || s.completions.isEmpty) return false;
  final day = dateOnly(today);
  final firstDone = s.completions
      .map((c) => parseDateKey(c.day))
      .reduce((a, b) => a.isBefore(b) ? a : b);
  var week = weekStart(firstDone);
  while (!addDays(week, 6).isAfter(day)) {
    if (_isPerfectWeek(s, week)) return true;
    week = addDays(week, 7);
  }
  return false;
}

bool _isPerfectWeek(HabitSnapshot s, DateTime monday) {
  var evaluated = 0;
  for (final habit in s.habits) {
    if (dateOnly(habit.createdAt).isAfter(monday)) continue;
    final goal = s.goalFor(habit);
    final done = s.completedDaysFor(habit.id);
    if (goal.isWeekly) {
      evaluated++;
      if (completionsInWeekOf(done, monday) < goal.safeWeeklyTarget) {
        return false;
      }
      continue;
    }
    for (var i = 0; i < 7; i++) {
      final d = addDays(monday, i);
      if (!isScheduledOn(goal.weekdays, d)) continue;
      evaluated++;
      if (!done.contains(d)) return false;
    }
  }
  return evaluated > 0;
}

/// Conquistas já celebradas, com a data de desbloqueio (SharedPreferences).
/// Uma vez desbloqueada a medalha não some, mesmo se o hábito for apagado.
class AchievementLedger {
  const AchievementLedger(this.unlockedAt);

  final Map<String, DateTime> unlockedAt;

  static const prefKey = 'achievements_unlocked';

  static AchievementLedger decode(String? raw) {
    if (raw == null || raw.isEmpty) return const AchievementLedger({});
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AchievementLedger({
        for (final e in map.entries)
          if (DateTime.tryParse('${e.value}') != null)
            e.key: DateTime.parse('${e.value}'),
      });
    } catch (_) {
      return const AchievementLedger({});
    }
  }

  String encode() => jsonEncode({
    for (final e in unlockedAt.entries) e.key: e.value.toIso8601String(),
  });

  /// Novas conquistas em [computed] que ainda não estavam no registro.
  List<Achievement> newlyUnlocked(Set<String> computed) => [
    for (final a in achievements)
      if (computed.contains(a.id) && !unlockedAt.containsKey(a.id)) a,
  ];

  AchievementLedger merge(Iterable<String> ids, DateTime when) =>
      AchievementLedger({
        ...unlockedAt,
        for (final id in ids) id: unlockedAt[id] ?? when,
      });

  bool isUnlocked(String id) => unlockedAt.containsKey(id);
}
