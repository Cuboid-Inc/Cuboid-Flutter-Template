import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class InvoiceDateCard extends StatelessWidget {
  const InvoiceDateCard({super.key, required this.label, this.date});

  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => ListCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date == null ? '—' : Formatters.date(date!),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 14.5,
          ),
        ),
      ],
    ),
  );
}
