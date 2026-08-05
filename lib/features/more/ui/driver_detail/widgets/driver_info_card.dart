import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    super.key,
    required this.driver,
    required this.supplierName,
  });

  final Driver driver;
  final String supplierName;

  @override
  Widget build(BuildContext context) {
    final licenceNearExpiry =
        driver.licenceExpiry != null &&
        driver.licenceExpiry!.difference(DateTime.now()).inDays <= 30;
    final identityNearExpiry =
        driver.identityExpiry != null &&
        driver.identityExpiry!.difference(DateTime.now()).inDays <= 30;

    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DRIVER INFORMATION',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.6,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DetailRow(label: 'Full Name', value: driver.name),
          DetailRow(label: 'Phone Number', value: driver.phone ?? '—'),
          DetailRow(
            label: 'Employment Status',
            value: driver.employment == Responsibility.operator
                ? 'Operator'
                : 'Subcontracted',
          ),
          if (driver.employment == Responsibility.customer)
            DetailRow(label: 'Supplier Name', value: supplierName),
          DetailRow(
            label: 'Licence Number',
            value: driver.licenceNumber ?? '—',
          ),
          DetailRow(
            label: 'Licence Expiry',
            value: driver.licenceExpiry != null
                ? '${Formatters.date(driver.licenceExpiry!)}${licenceNearExpiry ? " (Expiring soon)" : ""}'
                : '—',
            valueColor: licenceNearExpiry ? Colors.orange.shade800 : null,
          ),
          DetailRow(
            label: 'Identity / Visa Ref',
            value: driver.identityReference ?? '—',
          ),
          DetailRow(
            label: 'Identity Expiry',
            value: driver.identityExpiry != null
                ? '${Formatters.date(driver.identityExpiry!)}${identityNearExpiry ? " (Expiring soon)" : ""}'
                : '—',
            valueColor: identityNearExpiry ? Colors.orange.shade800 : null,
          ),
          if (driver.notes != null && driver.notes!.isNotEmpty)
            DetailRow(label: 'Notes', value: driver.notes!),
        ],
      ),
    );
  }
}
