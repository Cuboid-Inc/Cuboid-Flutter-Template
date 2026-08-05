import 'package:cuboid_flutter_template/features/reports/data/report_type.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';

extension ReportTypeMeta on ReportType {
  String get title => switch (this) {
    ReportType.profit => 'Operational profit',
    ReportType.ownership => 'Owned vs external',
    ReportType.vehicleProfit => 'Vehicle profit',
    ReportType.expenses => 'Expense summary',
    ReportType.cashbook => 'Cashbook',
    ReportType.unbilled => 'Unbilled work',
    ReportType.unpaid => 'Unpaid invoices',
    ReportType.expiry => 'Expiring documents',
  };
  String get subtitle => switch (this) {
    ReportType.profit => 'Revenue, payables, expenses',
    ReportType.ownership => 'Customer net revenue',
    ReportType.vehicleProfit => 'Per vehicle',
    ReportType.expenses => 'By category',
    ReportType.cashbook => 'Cleared movement',
    ReportType.unbilled => 'Completed work',
    ReportType.unpaid => 'Outstanding balances',
    ReportType.expiry => 'Next 30 days',
  };
  IconData get icon => switch (this) {
    ReportType.profit => CupertinoIcons.chart_bar_alt_fill,
    ReportType.ownership => CupertinoIcons.car_detailed,
    ReportType.vehicleProfit => CupertinoIcons.speedometer,
    ReportType.expenses => CupertinoIcons.doc_text_fill,
    ReportType.cashbook => CupertinoIcons.money_dollar_circle_fill,
    ReportType.unbilled => CupertinoIcons.doc_on_doc_fill,
    ReportType.unpaid => CupertinoIcons.exclamationmark_triangle_fill,
    ReportType.expiry => CupertinoIcons.calendar_badge_minus,
  };
  Color get tint => switch (this) {
    ReportType.profit => AppColors.primary,
    ReportType.ownership => AppColors.primary,
    ReportType.vehicleProfit => AppColors.success,
    ReportType.expenses => AppColors.warning,
    ReportType.cashbook => AppColors.success,
    ReportType.unbilled => AppColors.muted,
    ReportType.unpaid => AppColors.danger,
    ReportType.expiry => AppColors.danger,
  };
  Color get tintBg => switch (this) {
    ReportType.profit => AppColors.chipBg,
    ReportType.ownership => AppColors.chipBg,
    ReportType.vehicleProfit => AppColors.successBg,
    ReportType.expenses => AppColors.warningBg,
    ReportType.cashbook => AppColors.successBg,
    ReportType.unbilled => AppColors.neutralChipBg,
    ReportType.unpaid => AppColors.dangerBg,
    ReportType.expiry => AppColors.dangerBg,
  };
}
