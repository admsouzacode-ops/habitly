import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/data/app_database.dart';

void main() {
  test('migra schema v1 -> v2 preservando hábitos e conclusões', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        // Schema exatamente como gerado na versão 1 (app 1.0.0+4).
        raw.execute('''
CREATE TABLE IF NOT EXISTS "habits" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL CHECK(LENGTH("name") BETWEEN 1 AND 80), "icon" TEXT NOT NULL DEFAULT '🌱', "color_value" INTEGER NOT NULL DEFAULT 4281236786, "weekdays" TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7', "reminder" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE IF NOT EXISTS "completions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "habit_id" INTEGER NOT NULL REFERENCES habits (id) ON DELETE CASCADE, "day" TEXT NOT NULL, "completed_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), UNIQUE("habit_id", "day"));
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

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.first, 2);
    final index = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_completions_day'",
        )
        .get();
    expect(index, hasLength(1));
    await db.close();
  });

  test('instalação nova cria schema v2', () async {
    final db = AppDatabase.memory();
    expect(db.schemaVersion, 2);
    await db.insertHabit(HabitsCompanion.insert(name: 'Água'));
    expect(await db.habitCount(), 1);
    await db.close();
  });
}
