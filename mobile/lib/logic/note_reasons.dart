/// Motivos rápidos para a nota do dia ("Por que não consegui?").
///
/// O [code] é o valor gravado no banco (estável); o [label] é o texto em pt-BR.
enum NoteReason {
  semTempo('sem_tempo', 'Sem tempo', '⏰'),
  cansaco('cansaco', 'Cansaço', '😴'),
  esqueci('esqueci', 'Esqueci', '🤔'),
  doente('doente', 'Doente', '🤒'),
  imprevisto('imprevisto', 'Imprevisto', '⚡'),
  outro('outro', 'Outro', '💬');

  const NoteReason(this.code, this.label, this.emoji);

  final String code;
  final String label;
  final String emoji;

  static NoteReason? fromCode(String? code) {
    if (code == null) return null;
    for (final r in NoteReason.values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

/// Tamanho máximo do texto livre da nota.
const maxNoteLength = 280;

class ReasonCount {
  const ReasonCount(this.reason, this.count);

  final NoteReason reason;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is ReasonCount && other.reason == reason && other.count == count;

  @override
  int get hashCode => Object.hash(reason, count);

  @override
  String toString() => 'ReasonCount(${reason.code}, $count)';
}

/// Dados mínimos de uma nota para agregação (independe do Drift).
class NoteEntry {
  const NoteEntry({required this.habitId, required this.reasonCode});

  final int habitId;
  final String? reasonCode;
}

class ReasonSummary {
  const ReasonSummary({
    required this.counts,
    required this.totalNotes,
    required this.uncategorized,
  });

  /// Motivos com pelo menos uma ocorrência, do mais comum para o menos.
  final List<ReasonCount> counts;

  /// Total de notas consideradas (com ou sem motivo).
  final int totalNotes;

  /// Notas só com texto, sem motivo rápido.
  final int uncategorized;

  int get categorized => totalNotes - uncategorized;

  bool get isEmpty => totalNotes == 0;
}

/// Conta os motivos das notas, no geral ou só de [habitId].
/// Empates seguem a ordem de [NoteReason.values].
ReasonSummary summarizeReasons(Iterable<NoteEntry> notes, {int? habitId}) {
  final counts = <NoteReason, int>{};
  var total = 0;
  var uncategorized = 0;
  for (final note in notes) {
    if (habitId != null && note.habitId != habitId) continue;
    total++;
    final reason = NoteReason.fromCode(note.reasonCode);
    if (reason == null) {
      uncategorized++;
    } else {
      counts[reason] = (counts[reason] ?? 0) + 1;
    }
  }
  final list = [
    for (final r in NoteReason.values)
      if ((counts[r] ?? 0) > 0) ReasonCount(r, counts[r]!),
  ];
  list.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.reason.index.compareTo(b.reason.index);
  });
  return ReasonSummary(
    counts: list,
    totalNotes: total,
    uncategorized: uncategorized,
  );
}
