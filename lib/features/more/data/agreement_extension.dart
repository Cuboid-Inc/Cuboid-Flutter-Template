import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/agreement.dart';
import 'package:cuboid_flutter_template/core/money.dart';

extension AgreementRow on Agreement {
  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'reference': reference,
    'name': name,
    'customer_id': customerId,
    'rate_model': rateModel.toJson(),
    'start_date': _dateToDatabase(startDate),
    'end_date': _dateToDatabase(endDate),
    'invoice_grouping': invoiceGrouping.toJson(),
    'base_rate': baseRate,
    'duty_days': dutyDays,
    'included_hours': includedHours,
    'overtime_rate': overtimeRate,
    'extra_day_rate': extraDayRate,
    'extra_trip_rate': extraTripRate,
    'vat_rate': vatRate,
    'driver_responsibility': driverResponsibility.toJson(),
    'fuel_responsibility': fuelResponsibility.toJson(),
    'maintenance_responsibility': maintenanceResponsibility.toJson(),
    'default_vehicle_id': defaultVehicleId,
    'purchase_order_reference': purchaseOrderReference,
    'payment_terms': paymentTerms.toJson(),
    'notes': notes,
    'default_extras': defaultExtras,
  };

  static Agreement fromRow(Map<String, dynamic> row) => Agreement(
    id: row['id'] as String,
    reference: row['reference'] as String,
    name: row['name'] as String,
    customerId: row['customer_id'] as String,
    rateModel: enumFromJson(row['rate_model'] as String, RateModel.values),
    startDate: _dateFromDatabase(row['start_date']),
    endDate: _dateFromDatabase(row['end_date']),
    invoiceGrouping: enumFromJson(
      row['invoice_grouping'] as String,
      InvoiceGrouping.values,
    ),
    baseRate: roundMoney(row['base_rate'] as num),
    dutyDays: (row['duty_days'] as num).toInt(),
    includedHours: (row['included_hours'] as num).toInt(),
    overtimeRate: roundMoney(row['overtime_rate'] as num),
    extraDayRate: roundMoney(row['extra_day_rate'] as num),
    extraTripRate: roundMoney(row['extra_trip_rate'] as num),
    vatRate: row['vat_rate'] as num,
    driverResponsibility: enumFromJson(
      row['driver_responsibility'] as String,
      Responsibility.values,
    ),
    fuelResponsibility: enumFromJson(
      row['fuel_responsibility'] as String,
      Responsibility.values,
    ),
    maintenanceResponsibility: enumFromJson(
      row['maintenance_responsibility'] as String,
      Responsibility.values,
    ),
    defaultVehicleId: row['default_vehicle_id'] as String?,
    purchaseOrderReference: row['purchase_order_reference'] as String?,
    paymentTerms: enumFromJson(
      row['payment_terms'] as String,
      PaymentTerms.values,
    ),
    notes: row['notes'] as String?,
    defaultExtras: _extrasFromDatabase(row['default_extras']),
    isArchived: row['is_archived'] as bool,
  );
}

String? _dateToDatabase(DateTime? value) =>
    value?.toIso8601String().split('T').first;

DateTime? _dateFromDatabase(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);

Map<String, num> _extrasFromDatabase(dynamic value) {
  if (value is! Map) return {};
  return {
    for (final entry in value.entries)
      entry.key.toString(): roundMoney(entry.value as num),
  };
}
