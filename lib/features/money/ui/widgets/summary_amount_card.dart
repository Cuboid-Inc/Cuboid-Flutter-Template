import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

/// ListCard showing a label on the left and a large amount on the right,
/// used as the headline figure on money detail screens.
class SummaryAmountCard extends StatelessWidget {
  const SummaryAmountCard({
    super.key,
    required this.label,
    required this.amount,
    this.color = AppColors.danger,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => ListCard(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            fontSize: 14.5,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: color,
          ),
        ),
      ],
    ),
  );
}
