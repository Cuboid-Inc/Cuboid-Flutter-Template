import 'dart:convert';

import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/work_order.dart';
import 'package:fleetgo/features/money/data/money_extensions.dart';

export 'package:fleetgo/core/models/report_models.dart';

num _money(Object? value) => roundMoney((value as num?) ?? 0);
DateTime _date(Object value) => DateTime.parse(value.toString());

extension StatementRowMapping on StatementRow {
  static StatementRow fromRow(Map<String, dynamic> row) => StatementRow(
    partyId: row['party_id'] as String,
    date: _date(row['date']!),
    workOrderId: row['work_order_id'] as String,
    description: row['description'] as String,
    amount: _money(row['amount']),
  );
}

extension UnbilledWorkRowMapping on UnbilledWorkRow {
  static UnbilledWorkRow fromRow(Map<String, dynamic> row) {
    final allocations = _list(row['allocations']).map((item) {
      return VehicleAllocation(
        vehicleId: item['vehicle_id'] as String,
        driverId: item['driver_id'] as String?,
        source: enumFromJson(item['source'] as String, VehicleSource.values),
        supplierId: item['supplier_id'] as String?,
        supplierPayable: _money(item['supplier_payable']),
        notes: item['notes'] as String?,
      );
    }).toList();
    final lines = _list(row['charge_lines']).map((item) {
      return ChargeLine(
        name: item['name'] as String,
        description: item['description'] as String?,
        quantity: _money(item['quantity']).toInt(),
        unitPrice: _money(item['unit_price']),
        unit: item['unit'] as String,
        discount: _money(item['discount']),
        vatRate: _money(item['vat_rate']),
      );
    }).toList();
    return UnbilledWorkRow(
      customerName: row['customer_name'] as String,
      workOrder: WorkOrder(
        id: row['work_order_id'] as String,
        number: row['number'] as String,
        customerId: row['customer_id'] as String,
        agreementId: row['agreement_id'] as String?,
        date: _date(row['date']!),
        pickup: row['pickup'] as String,
        destination: row['destination'] as String,
        workType: enumFromJson(row['work_type'] as String, WorkType.values),
        status: enumFromJson(row['status'] as String, WorkStatus.values),
        plannedStart: row['planned_start'] == null
            ? null
            : _date(row['planned_start']!),
        plannedEnd: row['planned_end'] == null
            ? null
            : _date(row['planned_end']!),
        customerJobReference: row['customer_job_reference'] as String?,
        description: row['description'] as String?,
        notes: row['notes'] as String?,
        allocations: allocations,
        chargeLines: lines,
      ),
    );
  }
}

extension UnpaidInvoiceRowMapping on UnpaidInvoiceRow {
  static UnpaidInvoiceRow fromRow(Map<String, dynamic> row) => UnpaidInvoiceRow(
    invoice: InvoiceRow.fromRow(row),
    balance: _money(row['balance']),
  );
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) return value.cast<Map<String, dynamic>>();
  if (value is String) {
    return (jsonDecode(value) as List).cast<Map<String, dynamic>>();
  }
  return const [];
}
