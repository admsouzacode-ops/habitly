import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/note_reasons.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  late int habitId;
  final day = DateTime(2026, 11, 10, 15, 30);

  setUp(() async {
    db = AppDatabase.memory();
    repo = HabitRepository(db);
    habitId = await repo.addHabit(
      name: 'Correr',
      icon: '🏃',
      colorValue: 0xFF2E7D32,
      weekdays: {1, 2, 3, 4, 5, 6, 7},
    );
  });

  tearDown(() => db.close());

  test('cria, lê, atualiza e exclui a nota do dia', () async {
    expect(await repo.noteFor(habitId: habitId, day: day), isNull);

    await repo.saveNote(
      habitId: habitId,
      day: day,
      note: '  Choveu muito  ',
      reason: NoteReason.imprevisto,
    );
    var note = await repo.noteFor(habitId: habitId, day: day);
    expect(note, isNotNull);
    expect(note!.day, '2026-11-10');
    expect(note.note, 'Choveu muito');
    expect(note.reason, 'imprevisto');
    final createdAt = note.createdAt;

    await repo.saveNote(
      habitId: habitId,
      day: day,
      note: 'Estava gripado',
      reason: NoteReason.doente,
    );
    note = await repo.noteFor(habitId: habitId, day: day);
    expect(note!.note, 'Estava gripado');
    expect(note.reason, 'doente');
    expect(note.createdAt, createdAt);
    expect(await db.allNotes(), hasLength(1));

    await repo.deleteNote(habitId: habitId, day: day);
    expect(await repo.noteFor(habitId: habitId, day: day), isNull);
  });

  test('aceita só motivo ou só texto; vazio apaga a nota', () async {
    await repo.saveNote(
      habitId: habitId,
      day: day,
      note: '',
      reason: NoteReason.esqueci,
    );
    expect((await repo.noteFor(habitId: habitId, day: day))!.note, '');

    await repo.saveNote(habitId: habitId, day: day, note: 'Só texto');
    final n = await repo.noteFor(habitId: habitId, day: day);
    expect(n!.reason, isNull);
    expect(n.note, 'Só texto');

    await repo.saveNote(habitId: habitId, day: day, note: '   ');
    expect(await repo.noteFor(habitId: habitId, day: day), isNull);
  });

  test('limita o texto a 280 caracteres', () async {
    await repo.saveNote(habitId: habitId, day: day, note: 'a' * 400);
    final n = await repo.noteFor(habitId: habitId, day: day);
    expect(n!.note.length, maxNoteLength);
  });

  test('nota continua após marcar o hábito como feito', () async {
    await repo.saveNote(
      habitId: habitId,
      day: day,
      note: 'Atrasou',
      reason: NoteReason.semTempo,
    );
    await repo.setCompleted(habitId: habitId, day: day, completed: true);
    final snap = await repo.loadSnapshot();
    expect(snap.isCompleted(habitId, day), isTrue);
    expect(snap.noteFor(habitId, day)?.note, 'Atrasou');
    expect(snap.hasNotesOn(day), isTrue);
  });

  test('dias passados têm notas independentes', () async {
    final yesterday = DateTime(2026, 11, 9);
    await repo.saveNote(habitId: habitId, day: day, note: 'Hoje');
    await repo.saveNote(
      habitId: habitId,
      day: yesterday,
      note: 'Ontem',
      reason: NoteReason.cansaco,
    );
    final snap = await repo.loadSnapshot();
    expect(snap.noteFor(habitId, day)?.note, 'Hoje');
    expect(snap.noteFor(habitId, yesterday)?.note, 'Ontem');
    expect(snap.notes, hasLength(2));
  });

  test('excluir hábito apaga as notas em cascata', () async {
    final other = await repo.addHabit(
      name: 'Ler',
      icon: '📚',
      colorValue: 0xFF2E7D32,
      weekdays: {1},
    );
    await repo.saveNote(habitId: habitId, day: day, note: 'x');
    await repo.saveNote(habitId: other, day: day, note: 'y');
    await repo.setCompleted(habitId: habitId, day: day, completed: true);

    await repo.deleteHabit(habitId);
    final notes = await db.allNotes();
    expect(notes.map((n) => n.habitId), [other]);
    expect(await db.allCompletions(), isEmpty);
  });

  test('FK em cascata funciona também via SQL direto', () async {
    await repo.saveNote(habitId: habitId, day: day, note: 'x');
    await db.customStatement('DELETE FROM habits WHERE id = $habitId');
    expect(await db.allNotes(), isEmpty);
  });

  test('watchSnapshot emite quando uma nota muda', () async {
    final stream = repo.watchSnapshot();
    final seen = <int>[];
    final sub = stream.listen((s) => seen.add(s.notes.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.saveNote(habitId: habitId, day: day, note: 'x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
