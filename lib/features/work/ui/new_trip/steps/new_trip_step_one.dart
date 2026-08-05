import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/new_trip_viewmodel.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/widgets/form_section_label.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_date_time_picker.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_dropdown.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewTripStepOne extends StatelessWidget {
  const NewTripStepOne({super.key, required this.vm});

  final NewTripViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer selection
        AppComboBox<Party>.async(
          label: 'who is the customer?',
          value: vm.selectedCustomer,
          placeholder: 'Tap to select customer...',
          itemLabelBuilder: (c) => c.name,
          fetchPage: vm.fetchCustomersPage,
          onChanged: vm.selectCustomer,
          addLabel: 'Add Customer',
          onAddPressed: vm.addCustomer,
        ),
        if (vm.matchingAgreements.length > 1) ...[
          const SizedBox(height: 18),
          AppDropdown<Agreement>(
            label: 'which agreement?',
            value: vm.selectedAgreement,
            items: vm.matchingAgreements,
            hintText: 'Tap to select agreement...',
            itemLabelBuilder: (a) => '${a.reference} · ${a.name}',
            onChanged: vm.selectAgreement,
          ),
        ],
        const SizedBox(height: 18),

        // Saved route selection (auto-fills pickup, destination, rate)
        AppComboBox<RouteRate>.async(
          label: 'saved routes',
          value: vm.selectedRoute,
          placeholder: 'Tap to select a saved route...',
          itemLabelBuilder: (r) => '${r.pickup} → ${r.destination}',
          itemSubtitleBuilder: (r) =>
              '${r.vehicleClass.label} · ${Formatters.money(r.rate)}',
          fetchPage: vm.fetchRouteRatesPage,
          onChanged: (r) => r != null ? vm.selectRoute(r) : null,
          addLabel: 'Add Saved Route',
          onAddPressed: vm.addRouteRate,
        ),
        const SizedBox(height: 18),

        // Date, time, and manual route fields
        const FormSectionLabel('WORK DATE & ROUTE'),
        const SizedBox(height: 8),
        AppDateTimePicker(
          label: 'Trip Date & Time',
          value: vm.tripDate,
          onChanged: vm.setTripDate,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Pickup place',
          controller: vm.pickup,
          hintText: 'e.g. Jebel Ali Port, Dubai',
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Destination',
          controller: vm.destination,
          hintText: 'e.g. Industrial Area 4, Sharjah',
        ),
      ],
    );
  }
}
