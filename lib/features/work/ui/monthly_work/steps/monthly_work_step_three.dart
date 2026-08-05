import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/features/work/ui/monthly_work/monthly_work_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_section_label.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/trip_total_card.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class MonthlyWorkStepThree extends StatelessWidget {
  const MonthlyWorkStepThree({super.key, required this.vm});

  final MonthlyWorkViewModel vm;

  @override
  Widget build(BuildContext context) {
    final agreement = vm.agreement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormSectionLabel('WORK DETAILS'),
        ListCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agreement == null
                    ? 'No agreement selected'
                    : '${agreement.reference} · ${agreement.name}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.date(vm.serviceDate),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FormSectionLabel('CHARGES'),
        ListCard(
          child: Column(
            children: [
              for (var index = 0; index < vm.charges.length; index++) ...[
                _ChargeRow(charge: vm.charges[index]),
                if (index < vm.charges.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        TripTotalCard(formattedTotal: Formatters.money(vm.total)),
      ],
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.charge});

  final MonthlyWorkCharge charge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  charge.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${charge.quantity} × ${Formatters.money(charge.rate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            Formatters.money(charge.lineTotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
