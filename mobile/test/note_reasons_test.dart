import 'package:flutter_test/flutter_test.dart';
import 'package:habitly/logic/note_reasons.dart';

void main() {
  NoteEntry n(int habit, String? reason) =>
      NoteEntry(habitId: habit, reasonCode: reason);

  test('rótulos em pt-BR na ordem dos chips', () {
    expect(NoteReason.values.map((r) => r.label), [
      'Sem tempo',
      'Cansaço',
      'Esqueci',
      'Doente',
      'Imprevisto',
      'Outro',
    ]);
    expect(NoteReason.fromCode('cansaco'), NoteReason.cansaco);
    expect(NoteReason.fromCode('desconhecido'), isNull);
    expect(NoteReason.fromCode(null), isNull);
  });

  test('vazio quando não há notas', () {
    final s = summarizeReasons([]);
    expect(s.isEmpty, isTrue);
    expect(s.counts, isEmpty);
    expect(s.totalNotes, 0);
  });

  final notes = [
    n(1, 'sem_tempo'),
    n(1, 'sem_tempo'),
    n(1, 'cansaco'),
    n(2, 'esqueci'),
    n(2, 'esqueci'),
    n(2, 'esqueci'),
    n(2, 'sem_tempo'),
    n(2, null),
    n(3, 'codigo_antigo'),
  ];

  test('conta motivos no geral, do mais comum ao menos', () {
    final s = summarizeReasons(notes);
    expect(s.counts, [
      const ReasonCount(NoteReason.semTempo, 3),
      const ReasonCount(NoteReason.esqueci, 3),
      const ReasonCount(NoteReason.cansaco, 1),
    ]);
    expect(s.totalNotes, 9);
    expect(s.uncategorized, 2);
    expect(s.categorized, 7);
  });

  test('filtra por hábito', () {
    final s1 = summarizeReasons(notes, habitId: 1);
    expect(s1.counts, [
      const ReasonCount(NoteReason.semTempo, 2),
      const ReasonCount(NoteReason.cansaco, 1),
    ]);
    expect(s1.uncategorized, 0);

    final s2 = summarizeReasons(notes, habitId: 2);
    expect(s2.counts.first, const ReasonCount(NoteReason.esqueci, 3));
    expect(s2.totalNotes, 5);
    expect(s2.uncategorized, 1);

    expect(summarizeReasons(notes, habitId: 99).isEmpty, isTrue);
  });
}
