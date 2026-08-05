import 'package:flutter/material.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/agreement.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/detail_row.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';

class AgreementInfoCard extends StatelessWidget {
  const AgreementInfoCard({
    super.key,
    required this.agreement,
    required this.customerName,
    required this.vehicleLabel,
  });

  final Agreement agreement;
  final String customerName;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AGREEMENT DETAILS',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.6,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DetailRow(label: 'Reference ID', value: agreement.reference),
          DetailRow(label: 'Agreement Name', value: agreement.name),
          DetailRow(label: 'Customer', value: customerName),
          DetailRow(
            label: 'Billing Model',
            value: agreement.rateModel == RateModel.perTrip
                ? 'Per Trip Rate'
                : 'Monthly Hire',
          ),
          DetailRow(
            label: 'Base Rate',
            value: Formatters.money(agreement.baseRate),
          ),
          DetailRow(label: 'VAT Rate', value: '${agreement.vatRate}%'),
          DetailRow(
            label: 'Payment Terms',
            value: agreement.paymentTerms.label,
          ),
          if (agreement.rateModel == RateModel.monthly) ...[
            DetailRow(
              label: 'Duty Days / Month',
              value: agreement.dutyDays.toString(),
            ),
            DetailRow(
              label: 'Included Hours / Month',
              value: agreement.includedHours.toString(),
            ),
            DetailRow(
              label: 'Overtime Rate',
              value: '${Formatters.money(agreement.overtimeRate)} / hr',
            ),
            DetailRow(
              label: 'Extra Day Rate',
              value: Formatters.money(agreement.extraDayRate),
            ),
            DetailRow(
              label: 'Extra Trip Rate',
              value: Formatters.money(agreement.extraTripRate),
            ),
          ],
          DetailRow(label: 'Default Vehicle', value: vehicleLabel),
          DetailRow(
            label: 'Start Date',
            value: agreement.startDate != null
                ? Formatters.date(agreement.startDate!)
                : '—',
          ),
          DetailRow(
            label: 'End Date',
            value: agreement.endDate != null
                ? Formatters.date(agreement.endDate!)
                : '—',
          ),
          if (agreement.notes != null && agreement.notes!.isNotEmpty)
            DetailRow(label: 'Notes', value: agreement.notes!),
        ],
      ),
    );
  }
}
