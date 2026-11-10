import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/logic/dates.dart';
import 'package:habitly/logic/note_reasons.dart';
import 'package:habitly/providers/providers.dart';

/// Abre a folha para escrever/editar/excluir a nota de [habit] em [day].
Future<void> showDayNoteSheet(
  BuildContext context, {
  required Habit habit,
  required DateTime day,
  HabitDayNote? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        DayNoteSheet(habit: habit, day: dateOnly(day), existing: existing),
  );
}

class DayNoteSheet extends ConsumerStatefulWidget {
  const DayNoteSheet({
    super.key,
    required this.habit,
    required this.day,
    this.existing,
  });

  final Habit habit;
  final DateTime day;
  final HabitDayNote? existing;

  @override
  ConsumerState<DayNoteSheet> createState() => _DayNoteSheetState();
}

class _DayNoteSheetState extends ConsumerState<DayNoteSheet> {
  late final TextEditingController _text;
  NoteReason? _reason;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.note ?? '');
    _reason = NoteReason.fromCode(widget.existing?.reason);
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _reason != null || _text.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(habitRepositoryProvider)
        .saveNote(
          habitId: widget.habit.id,
          day: widget.day,
          note: _text.text,
          reason: _reason,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Nota salva')));
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    await ref
        .read(habitRepositoryProvider)
        .deleteNote(habitId: widget.habit.id, day: widget.day);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Nota excluída')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isToday = dateOnly(DateTime.now()) == widget.day;
    final dayLabel = isToday
        ? 'Hoje, ${shortDateFormat.format(widget.day)}'
        : capitalizedDateHeading(widget.day);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.habit.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Por que não consegui?',
                        style: textTheme.titleLarge,
                      ),
                      Text(
                        '${widget.habit.name} · $dayLabel',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Motivo', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in NoteReason.values)
                  ChoiceChip(
                    key: ValueKey('reason-${r.code}'),
                    label: Text('${r.emoji} ${r.label}'),
                    selected: _reason == r,
                    onSelected: (sel) =>
                        setState(() => _reason = sel ? r : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('note-text'),
              controller: _text,
              maxLength: maxNoteLength,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Conte o que aconteceu hoje…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    key: const ValueKey('note-delete'),
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('note-save'),
                  onPressed: _saving || !_canSave ? null : _save,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha compacta "📝 Motivo · texto" para cards e listas.
class NotePreview extends StatelessWidget {
  const NotePreview({super.key, required this.note, this.maxLines = 1});

  final HabitDayNote note;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Row(
      key: const ValueKey('note-indicator'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_outlined, size: 14, color: scheme.tertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            noteSummary(note),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

String noteSummary(HabitDayNote note) {
  final reason = NoteReason.fromCode(note.reason);
  final parts = [
    if (reason != null) reason.label,
    if (note.note.trim().isNotEmpty) note.note.trim(),
  ];
  return parts.join(' · ');
}
