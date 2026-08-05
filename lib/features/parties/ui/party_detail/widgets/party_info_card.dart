import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/detail_row.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class PartyInfoCard extends StatelessWidget {
  const PartyInfoCard({super.key, required this.party});
  final Party party;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARTY INFORMATION',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.6,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DetailRow(label: 'Contact Person', value: party.contactPerson ?? '—'),
          DetailRow(label: 'Phone', value: party.phone ?? '—'),
          DetailRow(label: 'Email', value: party.email ?? '—'),
          DetailRow(label: 'Address', value: party.address ?? '—'),
          DetailRow(label: 'City', value: party.city ?? '—'),
          DetailRow(label: 'Country', value: party.country),
          DetailRow(label: 'Payment Terms', value: party.paymentTerms.label),
          if (party.trn != null && party.trn!.isNotEmpty)
            DetailRow(label: 'TRN / TIN', value: party.trn!),
          if (party.notes != null && party.notes!.isNotEmpty)
            DetailRow(label: 'Notes', value: party.notes!),
        ],
      ),
    );
  }
}
