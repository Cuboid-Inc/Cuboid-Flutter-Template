import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuickActionItem {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.hasOperations,
    required this.hasMoney,
    required this.onNewTrip,
    required this.onPaymentIn,
    required this.onAddExpense,
    required this.onPaymentOut,
  });

  final bool hasOperations;
  final bool hasMoney;
  final VoidCallback onNewTrip;
  final VoidCallback onPaymentIn;
  final VoidCallback onAddExpense;
  final VoidCallback onPaymentOut;

  @override
  Widget build(BuildContext context) {
    final items = <QuickActionItem>[
      if (hasOperations)
        QuickActionItem(
          label: 'New trip',
          icon: CupertinoIcons.plus_circle,
          bg: AppColors.chipBg,
          fg: AppColors.primary,
          onTap: onNewTrip,
        ),
      if (hasMoney) ...[
        QuickActionItem(
          label: 'Payment in',
          icon: CupertinoIcons.arrow_down_circle,
          bg: AppColors.successBg,
          fg: AppColors.success,
          onTap: onPaymentIn,
        ),
        QuickActionItem(
          label: 'Expense',
          icon: CupertinoIcons.doc_text,
          bg: AppColors.warningBg,
          fg: AppColors.warning,
          onTap: onAddExpense,
        ),
        QuickActionItem(
          label: 'Payment out',
          icon: CupertinoIcons.arrow_up_circle,
          bg: AppColors.dangerBg,
          fg: AppColors.danger,
          onTap: onPaymentOut,
        ),
      ],
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: _buildItem(context, items[i])),
              const SizedBox(width: s12),
              Expanded(
                child: i + 1 < items.length
                    ? _buildItem(context, items[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (i + 2 < items.length) const SizedBox(height: s12),
        ],
      ],
    );
  }

  Widget _buildItem(BuildContext context, QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: s12, horizontal: s12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(radiusMd),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05101828),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(radiusSm),
              ),
              child: Icon(item.icon, color: item.fg, size: 20),
            ),
            const SizedBox(width: s12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
