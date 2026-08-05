import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';

extension DriverRow on Driver {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'name': name,
    'phone': phone,
    'licence_number': licenceNumber,
    'licence_expiry': _dateToDatabase(licenceExpiry),
    'identity_reference': identityReference,
    'identity_expiry': _dateToDatabase(identityExpiry),
    'employment': employment.toJson(),
    'supplier_id': supplierId,
    'notes': notes,
  };

  static Driver fromRow(Map<String, dynamic> row) => Driver(
    id: row['id'] as String,
    name: row['name'] as String,
    phone: row['phone'] as String?,
    licenceNumber: row['licence_number'] as String?,
    licenceExpiry: _dateFromDatabase(row['licence_expiry']),
    identityReference: row['identity_reference'] as String?,
    identityExpiry: _dateFromDatabase(row['identity_expiry']),
    employment: enumFromJson(
      row['employment'] as String,
      Responsibility.values,
    ),
    supplierId: row['supplier_id'] as String?,
    notes: row['notes'] as String?,
    isArchived: row['is_archived'] as bool,
  );
}

String? _dateToDatabase(DateTime? value) =>
    value?.toIso8601String().split('T').first;

DateTime? _dateFromDatabase(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);
