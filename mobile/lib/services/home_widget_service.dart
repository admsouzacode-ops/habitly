import 'package:flutter/widgets.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/goals.dart';
import 'package:home_widget/home_widget.dart';

/// Provider nativo em android/app/src/main/kotlin/.../HabitlyWidgetProvider.kt
const habitlyWidgetAndroidName =
    'br.com.souzacode.habitly.HabitlyWidgetProvider';

/// Quantos hábitos cabem no widget (o layout tem 5 linhas fixas).
const widgetMaxRows = 5;

enum WidgetAction { toggle, plus }

class WidgetRow {
  const WidgetRow({
    required this.habitId,
    required this.title,
    required this.progress,
    required this.done,
    required this.action,
    required this.actionLabel,
  });

  final int habitId;
  final String title;
  final String progress;
  final bool done;
  final WidgetAction action;
  final String actionLabel;
}

class WidgetData {
  const WidgetData({
    required this.date,
    required this.header,
    required this.rows,
    required this.extra,
    required this.emptyMessage,
  });

  final String date;
  final String header;
  final List<WidgetRow> rows;

  /// Hábitos de hoje que não couberam no widget.
  final int extra;
  final String emptyMessage;
}

/// Monta o conteúdo do widget a partir do snapshot (puro, testável).
WidgetData buildWidgetData(HabitSnapshot s, DateTime now) {
  final today = dateOnly(now);
  final due = s.habitsDueOn(today);
  final done = due.where((h) => s.isCompleted(h.id, today)).length;
  // Pendentes primeiro, mantendo a ordem de criação.
  final ordered = [
    ...due.where((h) => !s.isCompleted(h.id, today)),
    ...due.where((h) => s.isCompleted(h.id, today)),
  ];
  final rows = <WidgetRow>[
    for (final h in ordered.take(widgetMaxRows)) _rowFor(s, h, today),
  ];
  return WidgetData(
    date: dateKey(today),
    header: due.isEmpty ? 'Hoje' : 'Hoje · $done/${due.length}',
    rows: rows,
    extra: ordered.length - rows.length,
    emptyMessage: s.habits.isEmpty
        ? 'Toque para criar seu primeiro hábito'
        : 'Nada agendado para hoje 🎉',
  );
}

WidgetRow _rowFor(HabitSnapshot s, Habit h, DateTime today) {
  final goal = s.goalFor(h);
  final done = s.isCompleted(h.id, today);
  final title = '${h.icon} ${h.name}';
  switch (goal.type) {
    case GoalType.quantity:
      final unit = goal.quantityUnit.trim();
      final value = formatAmount(s.amountFor(h.id, today));
      final target = formatAmount(goal.safeQuantityTarget);
      return WidgetRow(
        habitId: h.id,
        title: title,
        progress: unit.isEmpty ? '$value/$target' : '$value/$target $unit',
        done: done,
        action: WidgetAction.plus,
        actionLabel: '+${formatAmount(goal.safeQuantityStep)}',
      );
    case GoalType.weekly:
      return WidgetRow(
        habitId: h.id,
        title: title,
        progress: '${s.weekCount(h.id, today)}/${goal.safeWeeklyTarget} sem.',
        done: done,
        action: WidgetAction.toggle,
        actionLabel: done ? '✓' : '',
      );
    case GoalType.daily:
      final streak = s.streakOf(h, today).current;
      return WidgetRow(
        habitId: h.id,
        title: title,
        progress: done ? 'Feito' : (streak > 0 ? '🔥 $streak' : ''),
        done: done,
        action: WidgetAction.toggle,
        actionLabel: done ? '✓' : '',
      );
  }
}

/// Grava os dados no SharedPreferences do widget e pede o redesenho.
/// Também agenda atualizações logo após as próximas meias-noites.
Future<void> pushWidgetData(WidgetData data, {DateTime? now}) async {
  final entries = <String, Object?>{
    'date': data.date,
    'header': data.header,
    'count': data.rows.length,
    'extra': data.extra,
    'empty': data.emptyMessage,
  };
  for (var i = 0; i < widgetMaxRows; i++) {
    final row = i < data.rows.length ? data.rows[i] : null;
    entries['h${i}_id'] = row?.habitId ?? -1;
    entries['h${i}_title'] = row?.title ?? '';
    entries['h${i}_progress'] = row?.progress ?? '';
    entries['h${i}_done'] = row?.done ?? false;
    entries['h${i}_action'] = row?.action.name ?? 'toggle';
    entries['h${i}_label'] = row?.actionLabel ?? '';
  }
  for (final e in entries.entries) {
    final v = e.value;
    if (v is int) {
      await HomeWidget.saveWidgetData<int>(e.key, v);
    } else if (v is bool) {
      await HomeWidget.saveWidgetData<bool>(e.key, v);
    } else {
      await HomeWidget.saveWidgetData<String>(e.key, v as String?);
    }
  }
  await HomeWidget.updateWidget(qualifiedAndroidName: habitlyWidgetAndroidName);
  final base = dateOnly(now ?? DateTime.now());
  try {
    await HomeWidget.scheduleWidgetUpdates([
      for (var i = 1; i <= 3; i++)
        addDays(base, i).add(const Duration(seconds: 5)),
    ], qualifiedAndroidName: habitlyWidgetAndroidName);
  } catch (error) {
    debugPrint('Widget: agendamento da meia-noite falhou: $error');
  }
}

Future<void> syncHomeWidget(HabitSnapshot snapshot) async {
  try {
    await pushWidgetData(buildWidgetData(snapshot, DateTime.now()));
  } catch (error) {
    debugPrint('Widget: não foi possível atualizar: $error');
  }
}

/// Registra o callback que o widget chama em segundo plano.
Future<void> registerHomeWidgetCallback() async {
  try {
    await HomeWidget.registerInteractivityCallback(habitlyWidgetCallback);
  } catch (error) {
    debugPrint('Widget: callback não registrado: $error');
  }
}

/// Executado num engine Flutter em segundo plano quando o usuário toca no
/// widget (habitly://toggle?id=N, habitly://plus?id=N) ou quando ele precisa
/// recalcular o dia (habitly://refresh, depois da meia-noite).
@pragma('vm:entry-point')
Future<void> habitlyWidgetCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  try {
    final repo = HabitRepository(db);
    final today = dateOnly(DateTime.now());
    final id = int.tryParse(uri?.queryParameters['id'] ?? '');
    final action = uri?.host;
    if (id != null && (action == 'toggle' || action == 'plus')) {
      final habits = await db.getHabits();
      final habit = habits.where((h) => h.id == id).firstOrNull;
      if (habit != null) {
        await repo.quickAction(habit: habit, day: today);
      }
    }
    await pushWidgetData(buildWidgetData(await repo.loadSnapshot(), today));
  } catch (error, stack) {
    debugPrint('Widget: callback falhou: $error\n$stack');
  } finally {
    await db.close();
  }
}
