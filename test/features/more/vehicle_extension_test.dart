import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/more/data/vehicle_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and writes a vehicle with all fields', () {
    final vehicle = VehicleRow.fromRow({
      'id': 'vehicle-1',
      'plate_number': 'DXB-1',
      'label': 'Truck 1',
      'vehicle_class': 'three_ton',
      'ownership': 'external',
      'supplier_id': 'supplier-1',
      'make': 'Make',
      'model': 'Model',
      'year': 2025.9,
      'registration_expiry': '2026-08-09',
      'insurance_expiry': '2026-09-10',
      'inspection_expiry': '2026-10-11',
      'notes': 'Note',
      'is_archived': true,
    });

    expect(vehicle.vehicleClass, VehicleClass.threeTon);
    expect(vehicle.ownership, VehicleOwnership.external);
    expect(vehicle.year, 2025);
    expect(vehicle.isExternal, isTrue);
    expect(vehicle.toRow('tenant-1'), {
      'tenant_id': 'tenant-1',
      'plate_number': 'DXB-1',
      'label': 'Truck 1',
      'vehicle_class': 'three_ton',
      'ownership': 'external',
      'supplier_id': 'supplier-1',
      'make': 'Make',
      'model': 'Model',
      'year': 2025,
      'registration_expiry': '2026-08-09',
      'insurance_expiry': '2026-09-10',
      'inspection_expiry': '2026-10-11',
      'notes': 'Note',
    });
  });

  test('maps nullable vehicle values and owned status', () {
    final vehicle = VehicleRow.fromRow({
      'id': 'vehicle-2',
      'plate_number': 'DXB-2',
      'label': 'Truck 2',
      'vehicle_class': 'custom',
      'ownership': 'owned',
      'supplier_id': null,
      'make': null,
      'model': null,
      'year': null,
      'registration_expiry': null,
      'insurance_expiry': null,
      'inspection_expiry': null,
      'notes': null,
      'is_archived': false,
    });

    expect(vehicle.year, isNull);
    expect(vehicle.isExternal, isFalse);
    expect(vehicle.toRow('tenant-2')['registration_expiry'], isNull);
  });
}
