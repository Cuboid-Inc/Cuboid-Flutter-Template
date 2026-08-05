import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:fleetgo/ui/widgets/status_chip.dart';
import 'package:flutter/cupertino.dart';

import '../work_viewmodel.dart';

class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.work,
    required this.vm,
    required this.index,
  });
  final WorkOrder work;
  final WorkViewModel vm;
  final int index;
  @override
  Widget build(BuildContext context) => ListCard(
    onTap: () => vm.openDetail(work, index),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              work.number,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              vm.dateFor(work),
              style: const TextStyle(fontSize: 12, color: AppColors.mutedLight),
            ),
            const Spacer(),
            _status(work.status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          vm.customerFor(work),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                work.route,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            Text(
              vm.totalFor(work),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _status(WorkStatus status) => switch (status) {
    WorkStatus.planned => StatusChip.info(status.label),
    WorkStatus.completed => StatusChip.success(status.label),
    WorkStatus.billed => StatusChip.neutral(status.label),
    WorkStatus.canceled => StatusChip.neutral(status.label),
  };
}
