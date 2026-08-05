import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.name,
    required this.amount,
    required this.periodLabel,
    this.recordCount,
    this.recordCountLabel,
    this.onTap,
    this.isProfitHero = false,
  });

  final String name;
  final String amount;
  final String periodLabel;
  final int? recordCount;
  final String? recordCountLabel;
  final VoidCallback? onTap;
  final bool isProfitHero;

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${name.toUpperCase()} · $periodLabel',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.05,
            color: isProfitHero ? AppColors.mutedLight : AppColors.muted,
          ),
        ),
        const SizedBox(height: s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: isProfitHero ? 32 : 18.5,
                  fontWeight: FontWeight.w800,
                  color: isProfitHero ? AppColors.white : AppColors.ink,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.mutedLight,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${recordCount ?? 0} ${recordCountLabel ?? 'items'}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isProfitHero ? AppColors.mutedLight : AppColors.primary,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radiusMd),
      child: Container(
        padding: EdgeInsets.all(isProfitHero ? 18 : 14),
        decoration: BoxDecoration(
          color: isProfitHero ? AppColors.navy : AppColors.white,
          border: Border.all(
            color: isProfitHero ? Colors.transparent : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(radiusMd),
          boxShadow: isProfitHero
              ? cardShadow
              : const [
                  BoxShadow(
                    color: Color(0x05101828),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: cardContent,
      ),
    );
  }
}
