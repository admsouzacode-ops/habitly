import 'package:habitly/logic/dates.dart';

/// Tipos de meta de um hábito (coluna `goal_type`, schema v4).
enum GoalType {
  /// Dias específicos da semana (comportamento original).
  daily('daily'),

  /// X vezes por semana, em qualquer dia.
  weekly('weekly'),

  /// Quantidade por dia com meta e unidade (ex.: 2 litros).
  quantity('quantity');

  const GoalType(this.code);

  final String code;

  static GoalType parse(String? raw) {
    for (final t in values) {
      if (t.code == raw) return t;
    }
    return GoalType.daily;
  }

  String get label => switch (this) {
    GoalType.daily => 'Dias da semana',
    GoalType.weekly => 'Vezes por semana',
    GoalType.quantity => 'Quantidade',
  };
}

const allWeekdays = {1, 2, 3, 4, 5, 6, 7};

/// Unidades sugeridas no formulário de metas de quantidade.
const quantityUnitSuggestions = [
  'copos',
  'litros',
  'ml',
  'min',
  'páginas',
  'km',
  'passos',
  'vezes',
];

class HabitGoal {
  const HabitGoal({
    this.type = GoalType.daily,
    this.weekdays = allWeekdays,
    this.weeklyTarget = 3,
    this.quantityTarget = 1,
    this.quantityUnit = '',
    this.quantityStep = 1,
  });

  final GoalType type;

  /// Dias agendados (daily e quantity). Weekly fica disponível todos os dias.
  final Set<int> weekdays;
  final int weeklyTarget;
  final double quantityTarget;
  final String quantityUnit;
  final double quantityStep;

  bool get isWeekly => type == GoalType.weekly;
  bool get isQuantity => type == GoalType.quantity;

  /// Dia em que o hábito "conta" como agendado (weekly: todos os dias).
  bool availableOn(DateTime day) =>
      isWeekly || weekdays.contains(dateOnly(day).weekday);

  int get safeWeeklyTarget => weeklyTarget.clamp(1, 7);

  double get safeQuantityTarget => quantityTarget <= 0 ? 1 : quantityTarget;

  double get safeQuantityStep => quantityStep <= 0 ? 1 : quantityStep;

  /// Ex.: "2 litros por dia", "3x por semana", "Todos os dias".
  String summary() {
    switch (type) {
      case GoalType.weekly:
        return '${safeWeeklyTarget}x por semana';
      case GoalType.quantity:
        final unit = quantityUnit.trim();
        final amount = formatAmount(safeQuantityTarget);
        final base = unit.isEmpty ? '$amount por dia' : '$amount $unit por dia';
        return weekdays.length == 7
            ? base
            : '$base · ${weekdaysSummary(weekdays)}';
      case GoalType.daily:
        return weekdaysSummary(weekdays);
    }
  }
}

String weekdaysSummary(Set<int> weekdays) {
  if (weekdays.length == 7) return 'Todos os dias';
  if (weekdays.length == 5 && weekdays.containsAll({1, 2, 3, 4, 5})) {
    return 'Dias úteis';
  }
  if (weekdays.length == 2 && weekdays.containsAll({6, 7})) {
    return 'Fins de semana';
  }
  final sorted = weekdays.toList()..sort();
  return sorted.map((d) => weekdayLabels[d - 1]).join(', ');
}

/// Formata quantidades no padrão pt-BR sem zeros à toa: 2 → "2",
/// 1.5 → "1,5", 0.25 → "0,25".
String formatAmount(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
}

/// Lê números digitados em pt-BR ("1,5") ou com ponto ("1.5").
double? parseAmount(String raw) {
  final cleaned = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Conclusões na semana ISO (seg–dom) que contém [day].
int completionsInWeek(Set<DateTime> completedDays, DateTime day) {
  final start = weekStart(day);
  final end = addDays(start, 6);
  return completedDays
      .map(dateOnly)
      .where((d) => !d.isBefore(start) && !d.isAfter(end))
      .length;
}
