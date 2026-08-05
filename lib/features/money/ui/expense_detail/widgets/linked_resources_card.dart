import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Card listing the work order/vehicle/driver linked to an expense.
class LinkedResourcesCard extends StatelessWidget {
  const LinkedResourcesCard({
    super.key,
    this.workOrder,
    this.vehicle,
    this.driver,
    required this.onTapWorkOrder,
  });

  final WorkOrder? workOrder;
  final Vehicle? vehicle;
  final Driver? driver;
  final VoidCallback onTapWorkOrder;

  @override
  Widget build(BuildContext context) => ListCard(
    child: Column(
      children: [
        if (workOrder != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapWorkOrder,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Linked Work Order',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            fontSize: 13.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap to view trip sheets',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    workOrder!.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.muted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        if (vehicle != null) ...[
          if (workOrder != null) const Divider(height: 1),
          _linkRow('Linked Vehicle', vehicle!.label),
        ],
        if (driver != null) ...[
          if (workOrder != null || vehicle != null) const Divider(height: 1),
          _linkRow('Linked Driver', driver!.name),
        ],
      ],
    ),
  );

  Widget _linkRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            fontSize: 13.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 13.5,
          ),
        ),
      ],
    ),
  );
}
