import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AttentionActionTile extends StatelessWidget {
  const AttentionActionTile({
    super.key,
    required this.count,
    required this.labelText,
    required this.subtitleText,
    this.onTap,
    this.isLast = false,
  });

  final int count;
  final String labelText;
  final String subtitleText;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final countColor = count > 0 ? AppColors.primary : AppColors.muted;
    final countBg = count > 0 ? AppColors.chipBg : AppColors.neutralChipBg;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: countBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: countColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: AppColors.mutedLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
