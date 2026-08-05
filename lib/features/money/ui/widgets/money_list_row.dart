import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared row layout for entries in the Money screen's list segments
/// (invoices, settlements, payments, expenses, balances, statements).
class MoneyListRow extends StatelessWidget {
  const MoneyListRow({
    super.key,
    this.number = '',
    required this.title,
    required this.subtitle,
    required this.amount,
    this.trailing,
    this.note,
  });

  final String number;
  final String title;
  final String subtitle;
  final String amount;
  final Widget? trailing;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (number.isNotEmpty)
            Text(number, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          ?trailing,
        ],
      ),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
        ],
      ),
      if (note != null)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Balance $note',
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}
