import 'package:cuboid_flutter_template/core/enums/enums.dart';

class Vehicle {
  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.label,
    required this.vehicleClass,
    required this.ownership,
    this.supplierId,
    this.make,
    this.model,
    this.year,
    this.registrationExpiry,
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.notes,
    this.isArchived = false,
  });

  final String id;
  final String plateNumber;
  final String label;
  final VehicleClass vehicleClass;
  final VehicleOwnership ownership;
  final String? supplierId;
  final String? make;
  final String? model;
  final int? year;
  final DateTime? registrationExpiry;
  final DateTime? insuranceExpiry;
  final DateTime? inspectionExpiry;
  final String? notes;
  bool isArchived;

  bool get isExternal => ownership == VehicleOwnership.external;
}
