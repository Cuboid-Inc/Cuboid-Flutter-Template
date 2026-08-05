import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';

extension VehicleRow on Vehicle {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'plate_number': plateNumber,
    'label': label,
    'vehicle_class': vehicleClass.toJson(),
    'ownership': ownership.toJson(),
    'supplier_id': supplierId,
    'make': make,
    'model': model,
    'year': year,
    'registration_expiry': _dateToDatabase(registrationExpiry),
    'insurance_expiry': _dateToDatabase(insuranceExpiry),
    'inspection_expiry': _dateToDatabase(inspectionExpiry),
    'notes': notes,
  };

  static Vehicle fromRow(Map<String, dynamic> row) => Vehicle(
    id: row['id'] as String,
    plateNumber: row['plate_number'] as String,
    label: row['label'] as String,
    vehicleClass: enumFromJson(
      row['vehicle_class'] as String,
      VehicleClass.values,
    ),
    ownership: enumFromJson(
      row['ownership'] as String,
      VehicleOwnership.values,
    ),
    supplierId: row['supplier_id'] as String?,
    make: row['make'] as String?,
    model: row['model'] as String?,
    year: (row['year'] as num?)?.toInt(),
    registrationExpiry: _dateFromDatabase(row['registration_expiry']),
    insuranceExpiry: _dateFromDatabase(row['insurance_expiry']),
    inspectionExpiry: _dateFromDatabase(row['inspection_expiry']),
    notes: row['notes'] as String?,
    isArchived: row['is_archived'] as bool,
  );
}

String? _dateToDatabase(DateTime? value) =>
    value?.toIso8601String().split('T').first;

DateTime? _dateFromDatabase(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);
