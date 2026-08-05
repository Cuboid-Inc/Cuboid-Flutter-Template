import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Label + money value line item, used to list totals/balances under a
/// document's line items (e.g. Net, VAT, Total, Balance).
class AmountRow extends StatelessWidget {
  const AmountRow(
    this.label,
    this.amount, {
    super.key,
    this.strong = false,
    this.color,
  });

  final String label;
  final num amount;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        Text(
          Formatters.money(amount),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            fontSize: strong ? 17 : 13,
            color: color ?? AppColors.ink,
          ),
        ),
      ],
    ),
  );
}
