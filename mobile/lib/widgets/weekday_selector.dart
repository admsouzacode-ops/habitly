import 'package:flutter/material.dart';
import 'package:habitly/logic/dates.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(weekdayLabels[i]),
            selected: selected.contains(i + 1),
            onSelected: (value) {
              final next = {...selected};
              if (value) {
                next.add(i + 1);
              } else {
                next.remove(i + 1);
              }
              onChanged(next);
            },
            selectedColor: scheme.primaryContainer,
            showCheckmark: false,
          ),
      ],
    );
  }
}
