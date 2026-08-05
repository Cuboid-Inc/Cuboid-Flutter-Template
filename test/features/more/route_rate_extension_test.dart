import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/features/more/data/route_rate_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a route rate row and rounds default extras', () {
    final rate = RouteRateRow.fromRow({
      'id': 'rate-1',
      'applies_to': 'customer-1',
      'pickup': 'Dubai',
      'destination': 'Abu Dhabi',
      'vehicle_class': 'seven_ton',
      'rate': 100.005,
      'default_extras': {'toll': 12.345, 7: 2.999},
      'is_archived': true,
    });

    expect(rate.id, 'rate-1');
    expect(rate.vehicleClass, VehicleClass.sevenTon);
    expect(rate.rate, 100.01);
    expect(rate.defaultExtras, {'toll': 12.35, '7': 3.00});
    expect(rate.isArchived, isTrue);
  });

  test('uses empty extras for a non-map database value and maps to a row', () {
    final rate = RouteRate(
      id: 'rate-2',
      appliesTo: 'all',
      pickup: 'Dubai',
      destination: 'Sharjah',
      vehicleClass: VehicleClass.pickup,
      rate: 50.005,
      defaultExtras: const {'parking': 2.50},
    );

    expect(rate.toRow('tenant-1'), {
      'tenant_id': 'tenant-1',
      'applies_to': 'all',
      'pickup': 'Dubai',
      'destination': 'Sharjah',
      'vehicle_class': 'pickup',
      'rate': 50.005,
      'default_extras': {'parking': 2.50},
    });
    expect(
      RouteRateRow.fromRow({
        'id': 'rate-3',
        'applies_to': 'all',
        'pickup': 'A',
        'destination': 'B',
        'vehicle_class': 'pickup',
        'rate': 1,
        'default_extras': null,
        'is_archived': false,
      }).defaultExtras,
      isEmpty,
    );
  });
}
