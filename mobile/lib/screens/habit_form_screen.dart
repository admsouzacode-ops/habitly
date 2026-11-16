import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitly/data/app_database.dart';
import 'package:habitly/data/habit_repository.dart';
import 'package:habitly/logic/goals.dart';
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
  late GoalType _goalType;
  late int _weeklyTarget;
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;
  late final TextEditingController _stepController;
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
    final goal = habit == null ? const HabitGoal() : goalOf(habit);
    _goalType = goal.type;
    _weeklyTarget = goal.safeWeeklyTarget;
    if (goal.isWeekly) _weekdays = {1, 2, 3, 4, 5, 6, 7};
    _targetController = TextEditingController(
      text: habit != null && goal.isQuantity
          ? formatAmount(goal.safeQuantityTarget)
          : '',
    );
    _unitController = TextEditingController(
      text: goal.isQuantity ? goal.quantityUnit : '',
    );
    _stepController = TextEditingController(
      text: formatAmount(goal.isQuantity ? goal.safeQuantityStep : 1),
    );
  }

  HabitGoal _buildGoal() => HabitGoal(
    type: _goalType,
    weekdays: _goalType == GoalType.weekly ? allWeekdays : _weekdays,
    weeklyTarget: _weeklyTarget,
    quantityTarget: parseAmount(_targetController.text) ?? 1,
    quantityUnit: _unitController.text.trim(),
    quantityStep: parseAmount(_stepController.text) ?? 1,
  );

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
    _targetController.dispose();
    _unitController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_goalType != GoalType.weekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha pelo menos um dia da semana.')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(habitRepositoryProvider);
    if (_reminder != null && ref.read(reminderSyncEnabledProvider)) {
      final granted = await ref
          .read(reminderServiceProvider)
          .requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sem permissão de notificação o lembrete não vai aparecer. '
              'Você pode liberar nas configurações do Android.',
            ),
          ),
        );
      }
    }
    try {
      if (_isEditing) {
        await repo.updateHabit(
          id: widget.habit!.id,
          name: _nameController.text,
          icon: _icon,
          colorValue: _colorValue,
          weekdays: _weekdays,
          reminder: _encodeReminder(),
          goal: _buildGoal(),
        );
      } else {
        await repo.addHabit(
          name: _nameController.text,
          icon: _icon,
          colorValue: _colorValue,
          weekdays: _weekdays,
          reminder: _encodeReminder(),
          goal: _buildGoal(),
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
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (!mounted || picked == null) return;
    setState(() => _reminder = picked);
  }

  @override
  Widget build(BuildContext context) {
    final remindersOn = ref.watch(remindersEnabledProvider);
    final color = Color(_colorValue);
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
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(_icon, style: const TextStyle(fontSize: 34)),
                ),
              ),
            ),
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
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Meta', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<GoalType>(
              key: const ValueKey('goal-type'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: GoalType.daily, label: Text('Dias')),
                ButtonSegment(
                  value: GoalType.weekly,
                  label: Text('Por semana'),
                ),
                ButtonSegment(
                  value: GoalType.quantity,
                  label: Text('Quantidade'),
                ),
              ],
              selected: {_goalType},
              onSelectionChanged: (value) => setState(() {
                _goalType = value.first;
                if (_goalType == GoalType.weekly) {
                  _weekdays = {1, 2, 3, 4, 5, 6, 7};
                }
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _buildGoal().summary(),
              key: const ValueKey('goal-summary'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (_goalType == GoalType.weekly) ...[
              Text(
                'Quantas vezes por semana?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Menos',
                    onPressed: _weeklyTarget <= 1
                        ? null
                        : () => setState(() => _weeklyTarget--),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      '${_weeklyTarget}x por semana',
                      key: const ValueKey('weekly-target'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('weekly-plus'),
                    tooltip: 'Mais',
                    onPressed: _weeklyTarget >= 7
                        ? null
                        : () => setState(() => _weeklyTarget++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Em qualquer dia da semana (seg a dom). A sequência conta '
                'semanas seguidas com a meta batida.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_goalType == GoalType.quantity) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('quantity-target'),
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Meta por dia',
                        hintText: 'Ex.: 2',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (_goalType != GoalType.quantity) return null;
                        final v = parseAmount(value ?? '');
                        if (v == null || v <= 0) return 'Informe a meta.';
                        if (v > 100000) return 'Meta muito alta.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('quantity-unit'),
                      controller: _unitController,
                      maxLength: 16,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        hintText: 'Ex.: litros',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final unit in quantityUnitSuggestions)
                    ChoiceChip(
                      label: Text(unit),
                      selected: _unitController.text.trim() == unit,
                      onSelected: (_) =>
                          setState(() => _unitController.text = unit),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('quantity-step'),
                controller: _stepController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quanto soma cada toque no +',
                  hintText: 'Ex.: 1 ou 0,5',
                ),
                validator: (value) {
                  if (_goalType != GoalType.quantity) return null;
                  final v = parseAmount(value ?? '');
                  if (v == null || v <= 0) return 'Informe o incremento.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_goalType != GoalType.weekly) ...[
              Text(
                'Dias da semana',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              WeekdaySelector(
                selected: _weekdays,
                onChanged: (days) => setState(() => _weekdays = days),
              ),
            ],
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _reminder == null ? Icons.alarm_add_outlined : Icons.alarm_on,
                color: _reminder == null ? null : color,
              ),
              title: const Text('Lembrete'),
              subtitle: Text(
                _reminder == null
                    ? 'Toque para receber um aviso nos dias escolhidos.'
                    : remindersOn
                    ? _goalType == GoalType.weekly
                          ? 'Aviso às ${_reminder!.format(context)} todos os dias'
                          : 'Aviso às ${_reminder!.format(context)} nos dias escolhidos'
                    : 'Às ${_reminder!.format(context)} · lembretes desligados '
                          'nas Configurações',
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
