import 'package:flutter/material.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/detail_row.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';

class VehicleInfoCard extends StatelessWidget {
  const VehicleInfoCard({
    super.key,
    required this.vehicle,
    required this.supplierName,
  });

  final Vehicle vehicle;
  final String supplierName;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE INFORMATION',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.6,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DetailRow(label: 'Plate Number', value: vehicle.plateNumber),
          DetailRow(label: 'Display Label', value: vehicle.label),
          DetailRow(label: 'Ownership', value: vehicle.ownership.label),
          if (vehicle.ownership == VehicleOwnership.external)
            DetailRow(label: 'Supplier Name', value: supplierName),
          DetailRow(
            label: 'Make / Model',
            value: '${vehicle.make ?? "—"} / ${vehicle.model ?? "—"}',
          ),
          DetailRow(
            label: 'Year',
            value: vehicle.year != null ? vehicle.year!.toString() : '—',
          ),
          DetailRow(
            label: 'Reg Expiry',
            value: vehicle.registrationExpiry != null
                ? Formatters.date(vehicle.registrationExpiry!)
                : '—',
          ),
          DetailRow(
            label: 'Ins Expiry',
            value: vehicle.insuranceExpiry != null
                ? Formatters.date(vehicle.insuranceExpiry!)
                : '—',
          ),
          DetailRow(
            label: 'Insp Expiry',
            value: vehicle.inspectionExpiry != null
                ? Formatters.date(vehicle.inspectionExpiry!)
                : '—',
          ),
          if (vehicle.notes != null && vehicle.notes!.isNotEmpty)
            DetailRow(label: 'Notes', value: vehicle.notes!),
        ],
      ),
    );
  }
}
