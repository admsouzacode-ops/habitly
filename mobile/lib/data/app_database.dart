import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get icon => text().withDefault(const Constant('🌱'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF2E7D32))();

  /// Dias da semana ISO separados por vírgula: 1=seg ... 7=dom.
  TextColumn get weekdays =>
      text().withDefault(const Constant('1,2,3,4,5,6,7'))();

  /// Horário de lembrete (HH:mm) nos dias de [weekdays]. Nulo = sem lembrete.
  TextColumn get reminder => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'idx_completions_day', columns: {#day})
class Completions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Dia local no formato YYYY-MM-DD.
  TextColumn get day => text()();
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

@DriftDatabase(tables: [Habits, Completions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'habitly'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 (app 1.0.0+5): lembretes passam a disparar notificações.
        // Índice para consultas por dia e limpeza de horários inválidos
        // gravados pela v1 (o campo era só informativo).
        await m.createIndex(idxCompletionsDay);
        await customStatement(
          "UPDATE habits SET reminder = NULL "
          "WHERE reminder IS NOT NULL AND reminder NOT GLOB '[0-2][0-9]:[0-5][0-9]'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Habit>> watchHabits() =>
      (select(habits)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  Future<List<Habit>> getHabits() =>
      (select(habits)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Future<int> habitCount() async {
    final count = countAll();
    final query = selectOnly(habits)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertHabit(HabitsCompanion companion) =>
      into(habits).insert(companion);

  Future<void> updateHabitRow(int id, HabitsCompanion companion) =>
      (update(habits)..where((t) => t.id.equals(id))).write(companion);

  Future<void> deleteHabitById(int id) async {
    await (delete(completions)..where((t) => t.habitId.equals(id))).go();
    await (delete(habits)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Completion>> watchCompletions() => select(completions).watch();

  Stream<List<Completion>> watchCompletionsInRange(String from, String to) =>
      (select(
        completions,
      )..where((t) => t.day.isBetweenValues(from, to))).watch();

  Future<List<Completion>> completionsInRange(String from, String to) =>
      (select(
        completions,
      )..where((t) => t.day.isBetweenValues(from, to))).get();

  Future<List<Completion>> allCompletions() => select(completions).get();

  Future<void> setCompleted({
    required int habitId,
    required String day,
    required bool completed,
  }) async {
    if (completed) {
      await into(completions).insert(
        CompletionsCompanion.insert(habitId: habitId, day: day),
        mode: InsertMode.insertOrIgnore,
      );
    } else {
      await (delete(
        completions,
      )..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).go();
    }
  }
}
