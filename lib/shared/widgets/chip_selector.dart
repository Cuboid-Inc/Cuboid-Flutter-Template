import 'package:nemara_homes/core/theme/app_colors.dart';
import 'package:nemara_homes/core/theme/ui_helpers.dart';
import 'package:flutter/material.dart';

class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
    this.multiSelect = false,
  });

  final List<T> items;
  final List<T> selected;
  final ValueChanged<List<T>> onChanged;
  final String Function(T value)? labelBuilder;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: s8,
    runSpacing: s8,
    children: [
      for (final item in items)
        FilterChip(
          label: Text(labelBuilder?.call(item) ?? '$item'),
          selected: selected.contains(item),
          onSelected: (checked) {
            final next = [...selected];
            if (multiSelect) {
              checked ? next.add(item) : next.remove(item);
            } else {
              next
                ..clear()
                ..add(item);
            }
            onChanged(next);
          },
          selectedColor: AppColors.chipBg,
          checkmarkColor: AppColors.primary,
        ),
    ],
  );
}
