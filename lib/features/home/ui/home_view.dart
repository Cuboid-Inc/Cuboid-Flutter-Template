import 'package:cuboid_flutter_template/features/home/ui/home_viewmodel.dart';
import 'package:cuboid_flutter_template/features/home/ui/widgets/attention_action_tile.dart';
import 'package:cuboid_flutter_template/features/home/ui/widgets/dashboard_metric_card.dart';
import 'package:cuboid_flutter_template/features/home/ui/widgets/home_skeleton.dart';
import 'package:cuboid_flutter_template/features/home/ui/widgets/quick_action_grid.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/section_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key});

  @override
  void onViewModelReady(HomeViewModel viewModel) => viewModel.init();

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  Widget builder(BuildContext context, HomeViewModel vm, Widget? child) {
    if (vm.summary == null && vm.isBusy) {
      return const SafeArea(child: HomeSkeleton());
    }
    if (vm.summary == null) {
      return EmptyState(
        title: vm.errorMessage == null
            ? 'No dashboard data'
            : "Couldn't load dashboard",
        subtitle: vm.errorMessage ?? 'No summary is available for this period.',
        icon: vm.errorMessage == null
            ? CupertinoIcons.chart_bar
            : CupertinoIcons.exclamationmark_triangle_fill,
        iconColor: vm.errorMessage == null ? null : AppColors.danger,
        actionLabel: 'Try again',
        actionIcon: CupertinoIcons.arrow_clockwise,
        onAction: vm.load,
      );
    }

    final visibleAttentionItems = <AttentionItem>[];
    for (var i = 0; i < vm.attention.length; i++) {
      final item = vm.attention[i];
      final isVisible =
          (i == 0 && (vm.hasOperationsPermission || vm.hasMoneyPermission)) ||
          (i == 1 && vm.hasMoneyPermission) ||
          ((i == 2 || i == 3) && vm.hasOperationsPermission);
      if (isVisible) {
        visibleAttentionItems.add(item);
      }
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.refreshSummery,
        child: ListView(
          padding: const EdgeInsets.only(
            left: s16,
            right: s16,
            top: s16,
            bottom: 100,
          ),
          children: [
            // 1. Greeting & Period Picker
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    CupertinoIcons.car_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.tenantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        vm.greeting,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: vm.selectPeriod,
                  icon: Badge(
                    isLabelVisible: vm.hasCustomPeriod,
                    smallSize: 8,
                    child: const Icon(CupertinoIcons.calendar, size: 16),
                  ),
                  label: Text(
                    vm.periodLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Navy Blue Metrics Card (if hasMoneyPermission)
            if (vm.hasMoneyPermission) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.resultLabel.toUpperCase()} · ${vm.periodShort}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      vm.resultAmount,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vm.resultExplanation,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedLight,
                      ),
                    ),
                    const Divider(color: Color(0x1AFFFFFF)),
                    Row(
                      children: [
                        _heroStat(
                          'Revenue excl. VAT',
                          vm.revenueRaw,
                          const Color(0xFF4ADE80),
                        ),
                        _heroStat(
                          'Operating costs',
                          vm.operatingCostsRaw,
                          const Color(0xFFFDA4AF),
                        ),
                        _heroStat(
                          'Invoiced incl. VAT',
                          vm.billedRaw,
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASH MOVEMENT · ${vm.periodShort}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vm.cashFlow,
                      style: TextStyle(
                        fontSize: 24,
                        color: vm.summary!.cashFlow < 0
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      vm.cashFlowExplanation,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const Divider(height: 22),
                    Row(
                      children: [
                        _cashStat(
                          'Money received',
                          vm.received,
                          AppColors.success,
                        ),
                        const SizedBox(width: 16),
                        _cashStat('Money paid', vm.paidOut, AppColors.danger),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Quick Actions Grid
            QuickActionGrid(
              hasOperations: vm.hasOperationsPermission,
              hasMoney: vm.hasMoneyPermission,
              onNewTrip: vm.newTrip,
              onPaymentIn: vm.paymentIn,
              onAddExpense: vm.addExpense,
              onPaymentOut: vm.paymentOut,
            ),
            const SizedBox(height: 16),

            // 4. Receivables & Payables Summary (if hasMoneyPermission)
            if (vm.hasMoneyPermission) ...[
              Row(
                children: [
                  Expanded(
                    child: DashboardMetricCard(
                      name: 'Customers owe',
                      amount: vm.receivable,
                      periodLabel: 'ALL OPEN',
                      recordCount: vm.receivableCount,
                      recordCountLabel: vm.receivableCount == 1
                          ? 'unpaid invoice'
                          : 'unpaid invoices',
                      onTap: vm.openReceivables,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DashboardMetricCard(
                      name: 'We owe suppliers',
                      amount: vm.payable,
                      periodLabel: 'ALL OPEN',
                      recordCount: vm.payableCount,
                      recordCountLabel: vm.payableCount == 1
                          ? 'unpaid settlement'
                          : 'unpaid settlements',
                      onTap: vm.openPayables,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 5. Action Items
            if (visibleAttentionItems.isNotEmpty) ...[
              const SectionLabel('Needs attention'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < visibleAttentionItems.length; i++)
                      AttentionActionTile(
                        count: visibleAttentionItems[i].count,
                        labelText: visibleAttentionItems[i].title,
                        subtitleText: visibleAttentionItems[i].subtitle,
                        onTap: visibleAttentionItems[i].onTap,
                        isLast: i == visibleAttentionItems.length - 1,
                      ),
                  ],
                ),
              ),
            ],

            // ponytail: dev-only reseed button for local Supabase resets.
            // Remove alongside lib/core/dev/seed_demo_data.dart.
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: vm.isBusy ? null : vm.seedDemoData,
                icon: const Icon(CupertinoIcons.cube_box, size: 16),
                label: const Text('Seed demo data (dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedLight),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _cashStat(String label, String value, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}
