import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

/// One tile in the Money screen's segment grid (Invoices/Payments/etc).
class MoneySegmentTile extends StatelessWidget {
  const MoneySegmentTile({
    super.key,
    required this.segment,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final MoneySegment segment;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.navy : Colors.white,
        border: selected ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            segment.icon,
            color: selected ? Colors.white : AppColors.muted,
            size: 17,
          ),
          Text(
            segment.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.body,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 10.5, color: AppColors.mutedLight),
          ),
        ],
      ),
    ),
  );
}
