import 'package:flutter/material.dart';

/// Row of 7 circular day-of-week toggle buttons (Mon…Sun).
class DaySelector extends StatelessWidget {
  final List<int> selectedDays; // 1=Mon … 7=Sun
  final ValueChanged<List<int>> onChanged;
  final bool enabled;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.enabled = true,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = selectedDays.contains(day);
        return GestureDetector(
          onTap: enabled
              ? () {
                  final updated = List<int>.from(selectedDays);
                  selected ? updated.remove(day) : updated.add(day);
                  updated.sort();
                  onChanged(updated);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.all(
                color: selected ? cs.primary : cs.outline.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _labels[i],
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }
}
