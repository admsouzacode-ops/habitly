import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/note_reasons.dart';

// Schema exatamente como gerado na versão 1 (app 1.0.0+4).
const _v1Schema = '''
CREATE TABLE IF NOT EXISTS "habits" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL CHECK(LENGTH("name") BETWEEN 1 AND 80), "icon" TEXT NOT NULL DEFAULT '🌱', "color_value" INTEGER NOT NULL DEFAULT 4281236786, "weekdays" TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7', "reminder" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE IF NOT EXISTS "completions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "habit_id" INTEGER NOT NULL REFERENCES habits (id) ON DELETE CASCADE, "day" TEXT NOT NULL, "completed_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), UNIQUE("habit_id", "day"));
''';

// v2 (app 1.0.0+5) = v1 + índice por dia.
const _v2Schema =
    '$_v1Schema'
    'CREATE INDEX IF NOT EXISTS idx_completions_day ON completions (day);\n';

Future<int> _userVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data.values.first as int;
}

Future<bool> _tableExists(AppDatabase db, String name) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$name'",
      )
      .get();
  return rows.isNotEmpty;
}

void main() {
  test('migra schema v1 -> v3 preservando hábitos e conclusões', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
$_v1Schema
INSERT INTO habits (name, icon, reminder) VALUES ('Ler', '📚', '20:00');
INSERT INTO habits (name, reminder) VALUES ('Correr', 'lixo');
INSERT INTO completions (habit_id, day) VALUES (1, '2026-11-09');
PRAGMA user_version = 1;
''');
      },
    );
    final db = AppDatabase(executor);
    final habits = await db.getHabits();
    expect(habits.map((h) => h.name), ['Ler', 'Correr']);
    expect(habits[0].reminder, '20:00');
    expect(habits[1].reminder, isNull);
    expect(await db.allCompletions(), hasLength(1));

    expect(await _userVersion(db), 3);
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_completions_day'",
        )
        .get();
    expect(index, hasLength(1));
    expect(await _tableExists(db, 'habit_day_notes'), isTrue);
    expect(await db.allNotes(), isEmpty);
    await db.close();
  });

  test('migra schema v2 -> v3 preservando dados e criando notas', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
$_v2Schema
INSERT INTO habits (name, icon, color_value, weekdays, reminder) VALUES ('Meditar', '🧘', 4280391411, '1,3,5', '07:30');
INSERT INTO habits (name) VALUES ('Água');
INSERT INTO completions (habit_id, day) VALUES (1, '2026-11-08');
INSERT INTO completions (habit_id, day) VALUES (1, '2026-11-09');
INSERT INTO completions (habit_id, day) VALUES (2, '2026-11-09');
PRAGMA user_version = 2;
''');
      },
    );
    final db = AppDatabase(executor);
    final habits = await db.getHabits();
    expect(habits.map((h) => h.name), ['Meditar', 'Água']);
    expect(habits[0].weekdays, '1,3,5');
    expect(habits[0].reminder, '07:30');
    expect(habits[0].colorValue, 4280391411);
    expect(await db.allCompletions(), hasLength(3));
    expect(await _userVersion(db), 3);
    expect(await _tableExists(db, 'habit_day_notes'), isTrue);

    // A tabela nova funciona e respeita o (habitId, day) único.
    final repo = HabitRepository(db);
    final day = DateTime(2026, 11, 10);
    await repo.saveNote(
      habitId: 1,
      day: day,
      note: 'Reunião cedo',
      reason: NoteReason.semTempo,
    );
    await repo.saveNote(
      habitId: 1,
      day: day,
      note: 'Reunião cedo demais',
      reason: NoteReason.imprevisto,
    );
    final notes = await db.allNotes();
    expect(notes, hasLength(1));
    expect(notes.single.reason, 'imprevisto');
    await db.close();
  });

  test('instalação nova cria schema v3', () async {
    final db = AppDatabase.memory();
    expect(db.schemaVersion, 3);
    await db.insertHabit(HabitsCompanion.insert(name: 'Água'));
    expect(await db.habitCount(), 1);
    expect(await _tableExists(db, 'habit_day_notes'), isTrue);
    await db.close();
  });
}
