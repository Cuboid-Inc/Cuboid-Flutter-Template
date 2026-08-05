import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/features/reports/data/report_type.dart';
import 'package:fleetgo/features/reports/ui/report_detail/report_detail_viewmodel.dart';
import 'package:fleetgo/features/reports/ui/report_type_meta.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/ui/widgets/app_bar_ios.dart';
import 'package:fleetgo/ui/widgets/app_loading_indicator.dart';
import 'package:fleetgo/ui/widgets/empty_state.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class ReportDetailView extends StackedView<ReportDetailViewModel> {
  const ReportDetailView({super.key, required this.type, required this.period});

  final ReportType type;
  final Period period;

  @override
  void onViewModelReady(ReportDetailViewModel viewModel) => viewModel.init();

  @override
  ReportDetailViewModel viewModelBuilder(BuildContext context) =>
      ReportDetailViewModel(type: type, period: period);

  @override
  Widget builder(
    BuildContext context,
    ReportDetailViewModel vm,
    Widget? child,
  ) => Scaffold(
    appBar: AppBarIOS(
      title: type.title,
      actions: [
        AppBarIconAction(
          icon: CupertinoIcons.square_arrow_up,
          onPressed: vm.export,
        ),
      ],
    ),
    body: vm.isBusy
        ? const AppLoadingIndicator(message: 'Loading report')
        : vm.errorMessage != null
        ? EmptyState(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            iconColor: AppColors.danger,
            title: "Couldn't load report",
            subtitle: vm.errorMessage,
            actionLabel: 'Try again',
            actionIcon: CupertinoIcons.arrow_clockwise,
            onAction: vm.init,
          )
        : vm.rows.isEmpty
        ? EmptyState(
            icon: type.icon,
            title: 'Nothing to show',
            subtitle:
                '${type.subtitle} · ${Formatters.monthYear(period.start)}',
          )
        : ListView(
            padding: const EdgeInsets.all(s16),
            children: [
              Text(
                '${type.subtitle} · ${Formatters.monthYear(period.start)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: s12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == ReportType.expiry ? 'DOCUMENTS' : 'TOTAL',
                      style: const TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: s4),
                    Text(
                      type == ReportType.expiry
                          ? '${vm.rows.length}'
                          : Formatters.money(vm.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: s16),
              Text(
                'BREAKDOWN',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: s8),
              ListCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < vm.rows.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 60),
                      _row(vm.rows[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
  );

  Widget _row((String, String, String) row) {
    final amountColor = switch (type) {
      ReportType.unpaid || ReportType.expiry => AppColors.danger,
      ReportType.cashbook when row.$1 == 'Money in' => AppColors.success,
      ReportType.cashbook when row.$1 == 'Money out' => AppColors.danger,
      _ => AppColors.ink,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: s16 - 2, vertical: s12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: type.tintBg,
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Icon(type.icon, color: type.tint, size: 15),
          ),
          const SizedBox(width: s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  row.$2,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            row.$3,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
