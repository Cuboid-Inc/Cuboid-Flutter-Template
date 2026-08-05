import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:flutter/material.dart';

class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    this.labelBuilder,
  });

  final List<T> values;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelBuilder;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.neutralChipBg,
      borderRadius: BorderRadius.circular(radiusSm),
    ),
    child: Row(
      children: [
        for (final item in values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: s8),
                decoration: BoxDecoration(
                  color: item == value ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(radiusSm - 2),
                ),
                child: Text(
                  labelBuilder?.call(item) ?? '$item',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: item == value ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
