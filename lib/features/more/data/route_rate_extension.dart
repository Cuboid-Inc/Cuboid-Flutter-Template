import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/route_rate.dart';
import 'package:cuboid_flutter_template/core/money.dart';

extension RouteRateRow on RouteRate {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'applies_to': appliesTo,
    'pickup': pickup,
    'destination': destination,
    'vehicle_class': vehicleClass.toJson(),
    'rate': rate,
    'default_extras': defaultExtras,
  };

  static RouteRate fromRow(Map<String, dynamic> row) => RouteRate(
    id: row['id'] as String,
    appliesTo: row['applies_to'] as String,
    pickup: row['pickup'] as String,
    destination: row['destination'] as String,
    vehicleClass: enumFromJson(
      row['vehicle_class'] as String,
      VehicleClass.values,
    ),
    rate: roundMoney(row['rate'] as num),
    defaultExtras: _extrasFromDatabase(row['default_extras']),
    isArchived: row['is_archived'] as bool,
  );
}

Map<String, num> _extrasFromDatabase(dynamic value) {
  if (value is! Map) return {};
  return {
    for (final entry in value.entries)
      entry.key.toString(): roundMoney(entry.value as num),
  };
}
