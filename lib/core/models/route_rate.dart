import 'package:cuboid_flutter_template/core/enums/enums.dart';

class RouteRate {
  RouteRate({
    required this.id,
    required this.appliesTo,
    required this.pickup,
    required this.destination,
    required this.vehicleClass,
    required this.rate,
    this.defaultExtras = const {},
    this.isArchived = false,
  });

  final String id;
  final String appliesTo;
  final String pickup;
  final String destination;
  final VehicleClass vehicleClass;
  final num rate;
  final Map<String, num> defaultExtras;
  bool isArchived;
}
