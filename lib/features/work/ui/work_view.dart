import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/features/work/ui/work_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_button.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:cuboid_flutter_template/ui/widgets/empty_state.dart';
import 'package:cuboid_flutter_template/ui/widgets/paginated_list/paginated_list_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:stacked/stacked.dart';

import 'widgets/work_card.dart';
import 'widgets/work_filter.dart';

class WorkView extends StackedView<WorkViewModel> {
  const WorkView({super.key});
  @override
  void onViewModelReady(WorkViewModel viewModel) => viewModel.init();
  @override
  WorkViewModel viewModelBuilder(BuildContext context) => WorkViewModel();

  @override
  Widget builder(BuildContext context, WorkViewModel vm, Widget? child) =>
      SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(s16, s16, s16, s12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Work',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      AppOutlineButton(
                        onPressed: vm.openMonthlyExtra,
                        compact: true,
                        label: '+ Monthly work',
                      ),
                      SizedBox(width: 12),
                      AppButton(
                        onPressed: vm.openNewTrip,
                        compact: true,
                        label: '+ New trip',
                      ),
                    ],
                  ),
                  AppTextField(
                    label: '',
                    onChanged: vm.setQuery,
                    prefixIcon: Icon(CupertinoIcons.search),
                    hintText: 'Search customer, route, WO, driver…',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final filter in vm.filters)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: WorkFilter(
                              label: filter == null ? "All" : filter.label,
                              selected: vm.filter == filter,
                              onTap: () => vm.setFilter(filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PaginatedListView<WorkOrder>(
                controller: vm.pagination,
                onRefresh: vm.refreshList,
                padding: const EdgeInsets.fromLTRB(s16, 0, s16, 100),
                emptyWidget: EmptyState(
                  title: 'No work matches your search or filter',
                  actionLabel: 'New trip',
                  icon: CupertinoIcons.briefcase,
                  actionIcon: CupertinoIcons.add,
                  onAction: vm.openNewTrip,
                ),
                separator: const SizedBox(height: 10),
                itemBuilder: (_, work, index) =>
                    WorkCard(work: work, vm: vm, index: index),
              ),
            ),
          ],
        ),
      );
}
