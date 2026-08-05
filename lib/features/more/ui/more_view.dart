import 'package:cuboid_flutter_template/features/more/ui/more_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:cuboid_flutter_template/ui/widgets/section_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class MoreView extends StackedView<MoreViewModel> {
  const MoreView({super.key});

  @override
  void onViewModelReady(MoreViewModel viewModel) => viewModel.init();

  @override
  MoreViewModel viewModelBuilder(BuildContext context) => MoreViewModel();

  @override
  Widget builder(BuildContext context, MoreViewModel vm, Widget? child) {
    final masterData = [
      MoreMenuItem(
        title: 'Customers & Suppliers',
        subtitle:
            '${vm.menuCounts?.customers ?? 0} customers · ${vm.menuCounts?.suppliers ?? 0} suppliers',
        icon: CupertinoIcons.person_2_fill,
        onTap: vm.openParties,
      ),
      MoreMenuItem(
        title: 'Vehicles',
        subtitle:
            '${vm.menuCounts?.vehiclesActive ?? 0} active · ${vm.menuCounts?.vehiclesExternal ?? 0} external',
        icon: CupertinoIcons.car_detailed,
        tint: AppColors.success,
        tintBg: AppColors.successBg,
        onTap: vm.openVehicles,
      ),
      MoreMenuItem(
        title: 'Drivers',
        subtitle: '${vm.menuCounts?.drivers ?? 0} managed profiles',
        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
        tint: AppColors.warning,
        tintBg: AppColors.warningBg,
        onTap: vm.openDrivers,
      ),
      MoreMenuItem(
        title: 'Agreements',
        subtitle: '${vm.menuCounts?.agreements ?? 0} billing agreements',
        icon: CupertinoIcons.doc_text_fill,
        tint: AppColors.muted,
        tintBg: AppColors.neutralChipBg,
        onTap: vm.openAgreements,
      ),
      MoreMenuItem(
        title: 'Route rate card',
        subtitle:
            '${vm.menuCounts?.routeRates ?? 0} saved routes · auto-fills trips',
        icon: CupertinoIcons.arrow_branch,
        onTap: vm.openRouteRates,
      ),
    ];

    final admin = [
      if (vm.hasReports)
        MoreMenuItem(
          title: 'Reports',
          subtitle: 'Profit, balances, cashbook, expiries',
          icon: CupertinoIcons.chart_bar_alt_fill,
          onTap: vm.openReports,
        ),
      if (vm.isOwner)
        MoreMenuItem(
          title: 'Staff & access packs',
          subtitle:
              '${vm.menuCounts?.staff ?? 0} members · owner-only settings',
          icon: CupertinoIcons.shield_lefthalf_fill,
          tint: AppColors.success,
          tintBg: AppColors.successBg,
          onTap: vm.openStaff,
        ),
      if (vm.isOwner)
        MoreMenuItem(
          title: 'Business & branding',
          subtitle: 'Identity, TRN, invoice sequence, templates',
          icon: CupertinoIcons.gear_alt_fill,
          tint: AppColors.muted,
          tintBg: AppColors.neutralChipBg,
          onTap: vm.openBusinessProfile,
        ),
      if (vm.isOwner)
        MoreMenuItem(
          title: 'Opening data & backup',
          subtitle: 'Imported balances · weekly export',
          icon: CupertinoIcons.cloud_upload_fill,
          onTap: () => vm.toast('Backup is available after backend connect'),
        ),
    ];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.refreshSummery,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(s16, s16, s16, 100),
          children: [
            Row(
              children: [
                const Text(
                  'More',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: vm.busy(MoreBusy.logout) ? null : vm.logout,
                  icon: const Icon(
                    CupertinoIcons.square_arrow_left,
                    size: 16,
                    color: AppColors.danger,
                  ),

                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionLabel('Master data'),
            const SizedBox(height: 8),
            ListCard(padding: EdgeInsets.zero, child: _section(masterData)),
            const SizedBox(height: 16),
            const SectionLabel('Reports & admin'),
            const SizedBox(height: 8),
            ListCard(padding: EdgeInsets.zero, child: _section(admin)),
            const SizedBox(height: 20),
            Center(
              child: Text(
                vm.appVersion,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _section(List<MoreMenuItem> items) => Column(
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 60),
        _item(items[i]),
      ],
    ],
  );

  Widget _item(MoreMenuItem item) => InkWell(
    onTap: item.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: s16 - 2, vertical: s12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.tintBg,
              borderRadius: BorderRadius.circular(radiusSm),
            ),
            child: Icon(item.icon, color: item.tint, size: 18),
          ),
          const SizedBox(width: s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: AppColors.mutedLight,
          ),
        ],
      ),
    ),
  );
}
