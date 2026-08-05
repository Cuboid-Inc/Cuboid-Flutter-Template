import 'package:cuboid_flutter_template/core/config/formatters.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/features/more/ui/vehicle_detail/widgets/vehicle_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VehicleInfoCard renders ownership and optional details', (
    tester,
  ) async {
    final expiry = DateTime(2026, 8, 1);
    final vehicle = Vehicle(
      id: 'v1',
      plateNumber: 'A 123',
      label: 'Truck 1',
      vehicleClass: VehicleClass.sevenTon,
      ownership: VehicleOwnership.external,
      make: 'Make',
      model: 'Model',
      year: 2024,
      registrationExpiry: expiry,
      notes: 'Needs service',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleInfoCard(vehicle: vehicle, supplierName: 'Supplier'),
        ),
      ),
    );
    expect(find.text('VEHICLE INFORMATION'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Make / Model'), findsNWidgets(2));
    expect(find.text(Formatters.date(expiry)), findsOneWidget);
    expect(find.text('Needs service'), findsOneWidget);
  });
}
