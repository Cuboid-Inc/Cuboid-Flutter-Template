import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/features/reports/data/report_type.dart';
import 'package:fleetgo/features/reports/ui/report_type_meta.dart';
import 'package:fleetgo/features/reports/ui/reports_viewmodel.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class ReportsView extends StackedView<ReportsViewModel> {
  const ReportsView({super.key});

  @override
  ReportsViewModel viewModelBuilder(BuildContext context) => ReportsViewModel();

  @override
  Widget builder(BuildContext context, ReportsViewModel vm, Widget? child) =>
      Scaffold(
        appBar: AppBarIOS(
          title: 'Reports',
          actions: [
            AppBarTextAction(
              label: Formatters.monthYear(vm.period.start),
              onPressed: vm.choosePeriod,
              showDot: vm.hasCustomPeriod,
            ),
            AppBarIconAction(
              icon: CupertinoIcons.square_arrow_up,
              onPressed: vm.export,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(s16),
          children: [
            ListCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < ReportType.values.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 60),
                    _row(ReportType.values[i], vm),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _row(ReportType report, ReportsViewModel vm) => InkWell(
    onTap: () => vm.openReport(report),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: s16 - 2, vertical: s12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: report.tintBg,
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Icon(report.icon, color: report.tint, size: 18),
          ),
          const SizedBox(width: s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  report.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: AppColors.mutedLight,
          ),
        ],
      ),
    ),
  );
}
