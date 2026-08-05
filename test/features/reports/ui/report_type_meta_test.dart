import 'package:cuboid_flutter_template/features/reports/data/report_type.dart';
import 'package:cuboid_flutter_template/features/reports/ui/report_type_meta.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every report type to its display metadata', () {
    const expected = {
      ReportType.profit: (
        'Operational profit',
        'Revenue, payables, expenses',
        CupertinoIcons.chart_bar_alt_fill,
        AppColors.primary,
        AppColors.chipBg,
      ),
      ReportType.ownership: (
        'Owned vs external',
        'Customer net revenue',
        CupertinoIcons.car_detailed,
        AppColors.primary,
        AppColors.chipBg,
      ),
      ReportType.vehicleProfit: (
        'Vehicle profit',
        'Per vehicle',
        CupertinoIcons.speedometer,
        AppColors.success,
        AppColors.successBg,
      ),
      ReportType.expenses: (
        'Expense summary',
        'By category',
        CupertinoIcons.doc_text_fill,
        AppColors.warning,
        AppColors.warningBg,
      ),
      ReportType.cashbook: (
        'Cashbook',
        'Cleared movement',
        CupertinoIcons.money_dollar_circle_fill,
        AppColors.success,
        AppColors.successBg,
      ),
      ReportType.unbilled: (
        'Unbilled work',
        'Completed work',
        CupertinoIcons.doc_on_doc_fill,
        AppColors.muted,
        AppColors.neutralChipBg,
      ),
      ReportType.unpaid: (
        'Unpaid invoices',
        'Outstanding balances',
        CupertinoIcons.exclamationmark_triangle_fill,
        AppColors.danger,
        AppColors.dangerBg,
      ),
      ReportType.expiry: (
        'Expiring documents',
        'Next 30 days',
        CupertinoIcons.calendar_badge_minus,
        AppColors.danger,
        AppColors.dangerBg,
      ),
    };

    for (final type in ReportType.values) {
      final meta = expected[type]!;
      expect(type.title, meta.$1);
      expect(type.subtitle, meta.$2);
      expect(type.icon, meta.$3);
      expect(type.tint, meta.$4);
      expect(type.tintBg, meta.$5);
    }
  });
}
