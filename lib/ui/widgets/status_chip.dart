import 'package:flutter/material.dart';

import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';

/// Small rounded pill chip used for statuses (e.g. Planned, Paid, Void).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.fg,
    required this.bg,
  });

  factory StatusChip.success(String label) => StatusChip(
    label: label,
    fg: AppColors.successText,
    bg: AppColors.successBg,
  );

  factory StatusChip.warning(String label) =>
      StatusChip(label: label, fg: AppColors.warning, bg: AppColors.warningBg);

  factory StatusChip.danger(String label) =>
      StatusChip(label: label, fg: AppColors.danger, bg: AppColors.dangerBg);

  factory StatusChip.info(String label) =>
      StatusChip(label: label, fg: AppColors.primary, bg: AppColors.chipBg);

  factory StatusChip.neutral(String label) =>
      StatusChip(label: label, fg: AppColors.mutedLight, bg: AppColors.bg);

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: s12 - 2, vertical: s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
