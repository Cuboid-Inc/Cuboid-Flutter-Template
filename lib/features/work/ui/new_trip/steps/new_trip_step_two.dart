import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/driver.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/features/work/ui/new_trip/new_trip_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/widgets/app_combo_box.dart';
import 'package:flutter/material.dart';

class NewTripStepTwo extends StatelessWidget {
  const NewTripStepTwo({super.key, required this.vm});

  final NewTripViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle selection — ownership is auto-derived from the vehicle model
        AppComboBox<Vehicle>.async(
          label: 'Which vehicle?',
          value: vm.selectedVehicle,
          placeholder: 'Tap to select vehicle...',
          itemLabelBuilder: (v) => v.label,
          itemSubtitleBuilder: (v) =>
              '${v.vehicleClass.label} · ${v.ownership == VehicleOwnership.owned ? "Owned" : "External"}',
          fetchPage: vm.fetchVehiclesPage,
          onChanged: vm.selectVehicle,
        ),
        const SizedBox(height: 18),

        // Driver selection
        AppComboBox<Driver>.async(
          label: 'Driver',
          value: vm.selectedDriver,
          placeholder: 'Tap to select driver...',
          itemLabelBuilder: (d) => d.name,
          itemSubtitleBuilder: (d) => d.phone ?? '',
          fetchPage: vm.fetchDriversPage,
          onChanged: vm.selectDriver,
        ),
      ],
    );
  }
}
