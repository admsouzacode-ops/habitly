import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/providers/providers.dart';
import 'package:habitly/theme/habitly_theme.dart';
import 'package:habitly/widgets/weekday_selector.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _icon;
  late int _colorValue;
  late Set<int> _weekdays;
  TimeOfDay? _reminder;
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _icon = habit?.icon ?? '🌱';
    _colorValue = habit?.colorValue ?? habitColorPalette.first.toARGB32();
    _weekdays = habit == null
        ? {1, 2, 3, 4, 5, 6, 7}
        : parseWeekdays(habit.weekdays);
    _reminder = _parseReminder(habit?.reminder);
  }

  TimeOfDay? _parseReminder(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _encodeReminder() {
    final r = _reminder;
    if (r == null) return null;
    final h = r.hour.toString().padLeft(2, '0');
    final m = r.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha pelo menos um dia da semana.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(habitRepositoryProvider);
    try {
      if (_isEditing) {
        await repo.updateHabit(
          id: widget.habit!.id,
          name: _nameController.text,
          icon: _icon,
          colorValue: _colorValue,
          weekdays: _weekdays,
          reminder: _encodeReminder(),
        );
      } else {
        await repo.addHabit(
          name: _nameController.text,
          icon: _icon,
          colorValue: _colorValue,
          weekdays: _weekdays,
          reminder: _encodeReminder(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir hábito?'),
        content: Text(
          '“${widget.habit!.name}” e o histórico de conclusões serão '
          'apagados deste aparelho. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(habitRepositoryProvider).deleteHabit(widget.habit!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Horário do lembrete',
      cancelText: 'Limpar',
      confirmText: 'OK',
    );
    // showTimePicker returns null on cancel. We still offer an explicit clear.
    if (!mounted) return;
    setState(() => _reminder = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar hábito' : 'Novo hábito'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Excluir hábito',
              onPressed: _saving ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex.: Beber água',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe um nome para o hábito.';
                }
                if (value.trim().length > 80) {
                  return 'Use no máximo 80 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in habitIconOptions)
                  ChoiceChip(
                    label: Text(icon, style: const TextStyle(fontSize: 18)),
                    selected: _icon == icon,
                    onSelected: (_) => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Cor', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in habitColorPalette)
                  InkWell(
                    onTap: () => setState(() => _colorValue = color.toARGB32()),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: _colorValue == color.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Dias da semana', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            WeekdaySelector(
              selected: _weekdays,
              onChanged: (days) => setState(() => _weekdays = days),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm_outlined),
              title: const Text('Lembrete (opcional)'),
              subtitle: Text(
                _reminder == null
                    ? 'Nenhum horário definido. O campo é só um registro, '
                        'sem notificação por enquanto.'
                    : 'Horário: ${_reminder!.format(context)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reminder != null)
                    IconButton(
                      tooltip: 'Remover lembrete',
                      onPressed: () => setState(() => _reminder = null),
                      icon: const Icon(Icons.close),
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _pickReminder,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Salvar alterações' : 'Criar hábito'),
            ),
          ],
        ),
      ),
    );
  }
}
