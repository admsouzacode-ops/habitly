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

  /// Tipo de meta (v4, app 1.0.0+7): 'daily' (dias da semana), 'weekly'
  /// (X vezes por semana, qualquer dia) ou 'quantity' (quantidade por dia).
  /// Hábitos antigos ficam 'daily'.
  TextColumn get goalType => text().withDefault(const Constant('daily'))();

  /// Meta semanal (vezes por semana) quando goalType = 'weekly'.
  IntColumn get weeklyTarget => integer().withDefault(const Constant(3))();

  /// Meta diária quando goalType = 'quantity' (ex.: 2 litros, 8 copos).
  RealColumn get quantityTarget => real().withDefault(const Constant(1))();

  /// Unidade da meta de quantidade (ex.: 'litros', 'copos', 'min').
  TextColumn get quantityUnit => text().withDefault(const Constant(''))();

  /// Incremento do botão + (e do widget) para metas de quantidade.
  RealColumn get quantityStep => real().withDefault(const Constant(1))();
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

/// Nota do dia por hábito (v3, app 1.0.0+6): principalmente o motivo de
/// não ter cumprido o hábito naquele dia.
class HabitDayNotes extends Table {
  IntColumn get id => integer().autoIncrement()();

  // FK explícita: com drift_dev 2.31 + analyzer 10 o `.references()` não é
  // emitido no SQL gerado, então a cascata é declarada à mão.
  IntColumn get habitId => integer().customConstraint(
    'NOT NULL REFERENCES habits(id) ON DELETE CASCADE',
  )();

  /// Dia local no formato YYYY-MM-DD.
  TextColumn get day => text()();

  /// Texto livre (até 280 caracteres; pode ser vazio se houver motivo).
  TextColumn get note =>
      text().withLength(max: 280).withDefault(const Constant(''))();

  /// Código de [NoteReason] (ex.: 'sem_tempo'). Nulo = sem motivo rápido.
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

/// Progresso do dia em hábitos de quantidade (v4, app 1.0.0+7). A conclusão
/// do dia continua sendo uma linha em [Completions], gravada quando o valor
/// atinge a meta, para histórico/estatísticas seguirem funcionando.
class HabitAmounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().customConstraint(
    'NOT NULL REFERENCES habits(id) ON DELETE CASCADE',
  )();

  /// Dia local no formato YYYY-MM-DD.
  TextColumn get day => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

@DriftDatabase(tables: [Habits, Completions, HabitDayNotes, HabitAmounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'habitly'));

  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

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
      if (from < 3) {
        // v3 (app 1.0.0+6): notas do dia por hábito. Só cria a tabela nova;
        // hábitos e conclusões existentes não são tocados.
        await m.createTable(habitDayNotes);
      }
      if (from < 4) {
        // v4 (app 1.0.0+7): metas flexíveis. Colunas novas com DEFAULT, então
        // todos os hábitos existentes viram 'daily' com os mesmos dias da
        // semana; conclusões e notas não são tocadas.
        await m.addColumn(habits, habits.goalType);
        await m.addColumn(habits, habits.weeklyTarget);
        await m.addColumn(habits, habits.quantityTarget);
        await m.addColumn(habits, habits.quantityUnit);
        await m.addColumn(habits, habits.quantityStep);
        await m.createTable(habitAmounts);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // O widget da tela inicial grava pelo isolate de segundo plano; espera
      // o lock em vez de falhar com SQLITE_BUSY.
      await customStatement('PRAGMA busy_timeout = 5000');
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

  Future<void> deleteHabitById(int id) => transaction(() async {
    // As FKs já têm ON DELETE CASCADE; a limpeza explícita garante o mesmo
    // resultado mesmo se foreign_keys estiver desligado.
    await (delete(habitDayNotes)..where((t) => t.habitId.equals(id))).go();
    await (delete(habitAmounts)..where((t) => t.habitId.equals(id))).go();
    await (delete(completions)..where((t) => t.habitId.equals(id))).go();
    await (delete(habits)..where((t) => t.id.equals(id))).go();
  });

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

  Future<List<HabitDayNote>> allNotes() =>
      (select(habitDayNotes)..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.asc(t.habitId),
          ]))
          .get();

  Future<HabitDayNote?> noteFor(int habitId, String day) =>
      (select(habitDayNotes)
            ..where((t) => t.habitId.equals(habitId) & t.day.equals(day)))
          .getSingleOrNull();

  /// Cria ou atualiza a nota única de (hábito, dia), preservando createdAt.
  Future<void> upsertNote({
    required int habitId,
    required String day,
    required String note,
    String? reason,
  }) async {
    final now = DateTime.now();
    await into(habitDayNotes).insert(
      HabitDayNotesCompanion.insert(
        habitId: habitId,
        day: day,
        note: Value(note),
        reason: Value(reason),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      onConflict: DoUpdate(
        (_) => HabitDayNotesCompanion(
          note: Value(note),
          reason: Value(reason),
          updatedAt: Value(now),
        ),
        target: [habitDayNotes.habitId, habitDayNotes.day],
      ),
    );
  }

  Future<int> deleteNote(int habitId, String day) => (delete(
    habitDayNotes,
  )..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).go();

  Future<List<HabitAmount>> allAmounts() => select(habitAmounts).get();

  Future<HabitAmount?> amountFor(int habitId, String day) =>
      (select(habitAmounts)
            ..where((t) => t.habitId.equals(habitId) & t.day.equals(day)))
          .getSingleOrNull();

  /// Grava o valor do dia e mantém a conclusão em sincronia com a meta.
  Future<void> setAmount({
    required int habitId,
    required String day,
    required double amount,
    required double target,
  }) => transaction(() async {
    if (amount <= 0) {
      await (delete(
        habitAmounts,
      )..where((t) => t.habitId.equals(habitId) & t.day.equals(day))).go();
    } else {
      await into(habitAmounts).insert(
        HabitAmountsCompanion.insert(
          habitId: habitId,
          day: day,
          amount: Value(amount),
          updatedAt: Value(DateTime.now()),
        ),
        onConflict: DoUpdate(
          (_) => HabitAmountsCompanion(
            amount: Value(amount),
            updatedAt: Value(DateTime.now()),
          ),
          target: [habitAmounts.habitId, habitAmounts.day],
        ),
      );
    }
    await setCompleted(
      habitId: habitId,
      day: day,
      completed: amount > 0 && amount + 1e-9 >= target,
    );
  });
}
