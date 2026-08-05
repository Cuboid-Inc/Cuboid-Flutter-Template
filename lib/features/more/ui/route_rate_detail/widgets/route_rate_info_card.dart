import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/route_rate.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/widgets/detail_row.dart';
import 'package:fleetgo/ui/widgets/list_card.dart';
import 'package:flutter/material.dart';

class RouteRateInfoCard extends StatelessWidget {
  const RouteRateInfoCard({super.key, required this.routeRate});

  final RouteRate routeRate;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROUTE RATE DETAILS',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.6,
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          DetailRow(label: 'Customer Association', value: routeRate.appliesTo),
          DetailRow(
            label: 'Vehicle Class',
            value: routeRate.vehicleClass.label,
          ),
          DetailRow(label: 'Pickup Location', value: routeRate.pickup),
          DetailRow(
            label: 'Destination Location',
            value: routeRate.destination,
          ),
          DetailRow(
            label: 'Base Rate',
            value: Formatters.money(routeRate.rate),
          ),
          if (routeRate.defaultExtras.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              'DEFAULT EXTRAS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in routeRate.defaultExtras.entries)
              DetailRow(label: entry.key, value: Formatters.money(entry.value)),
          ],
        ],
      ),
    );
  }
}
